#!/usr/bin/env zx
$.verbose = false

/**
 * * helmReleaseDiff.mjs
 * * Runs `helm template` with your Helm values and then runs `dyff` across Flux HelmRelease manifests
 * @param --current-release   The source Flux HelmRelease to compare against the target
 * @param --incoming-release  The target Flux HelmRelease to compare against the source
 * @param --kubernetes-dir    The directory containing your Flux manifests including the HelmRepository manifests
 * * Limitations:
 * * Does not work with multiple HelmRelease manifests in the same YAML document
 * * All Kubernetes manifests must be in a single top level directory (nested folders under that is fine)
 * * Requires kustomization.yaml files in-order to build the full helm release
 */
const CurrentRelease  = argv['current-release']
const IncomingRelease = argv['incoming-release']
const KubernetesDir   = argv['kubernetes-dir']

const dyff      = await which('dyff')
const helm      = await which('helm')
const kustomize = await which('kustomize')

async function helmRelease (releaseFile) {
  const helmRelease = await fs.readFile(releaseFile, 'utf8')
  const doc = YAML.parseAllDocuments(helmRelease).map((item) => item.toJS())
  const release = doc.filter((item) =>
    item.apiVersion === 'helm.toolkit.fluxcd.io/v2beta1'
      && item.kind === 'HelmRelease'
  )
  return release[0]
}

async function helmRepository (kubernetesDir, releaseName) {
  const files = await globby([`${kubernetesDir}/**/*.yaml`])
  for await (const file of files) {
    const contents = await fs.readFile(file, 'utf8')
    const repository = YAML.parseAllDocuments(contents).map((item) => item.toJS())
    if (repository[0] && 'apiVersion' in repository[0] && repository[0].apiVersion === 'source.toolkit.fluxcd.io/v1beta2'
        && 'kind' in repository[0] && repository[0].kind === 'HelmRepository'
        && 'metadata' in repository[0] && 'name' in repository[0].metadata && repository[0].metadata.name === releaseName)
    {
      return repository[0]
    }
  }
}

async function kustomizeBuild (releaseBaseDir, releaseName) {
  const build = await $`${kustomize} build --load-restrictor=LoadRestrictionsNone ${releaseBaseDir}`
  const docs = YAML.parseAllDocuments(build.stdout).map((item) => item.toJS())
  const release = docs.filter((item) =>
    item.apiVersion === 'helm.toolkit.fluxcd.io/v2beta1'
      && item.kind === 'HelmRelease'
        && item.metadata.name === releaseName
  )
  return release[0]
}

async function helmTemplate (release, repository) {
  const values = new YAML.Document()
  values.contents = release.spec.values
  const valuesFile = await $`mktemp`
  await fs.writeFile(valuesFile.stdout.trim(), values.toString())

  // Template out our helm values into Kubernetes manifests
  let manifests
  if ('type' in repository.spec && repository.spec.type == 'oci') {
    manifests = await $`${helm} template --kube-version 1.27.1 --release-name ${release.metadata.name} --include-crds=false ${repository.spec.url}/${release.spec.chart.spec.chart} --version ${release.spec.chart.spec.version} --values ${valuesFile.stdout.trim()}`
  } else {
    await $`${helm} repo add ${release.spec.chart.spec.sourceRef.name} ${repository.spec.url}`
    manifests = await $`${helm} template --kube-version 1.27.1 --release-name ${release.metadata.name} --include-crds=false ${release.spec.chart.spec.sourceRef.name}/${release.spec.chart.spec.chart} --version ${release.spec.chart.spec.version} --values ${valuesFile.stdout.trim()}`
  }

  // Remove docs that are CustomResourceDefinition and keys which contain generated fields
  let documents = YAML.parseAllDocuments(manifests.stdout.trim())
  documents = documents.filter(doc => doc.get('kind') !== 'CustomResourceDefinition')
  documents.forEach(doc => {
    const del = (path) => doc.hasIn(path) ? doc.deleteIn(path) : false
    del(['metadata', 'labels'])
    del(['spec', 'template', 'metadata', 'annotations'])
    del(['spec', 'template', 'metadata', 'labels'])
  })

  const manifestsFile = await $`mktemp`
  await fs.writeFile(manifestsFile.stdout.trim(), documents.map(doc => doc.toString({directives: true})).join('\n'))
  return manifestsFile.stdout.trim()
}

// Generate current template from Helm values
const currentRelease = await helmRelease(CurrentRelease)
const currentBuild = await kustomizeBuild(path.dirname(CurrentRelease), currentRelease.metadata.name)
const currentRepository = await helmRepository(KubernetesDir, currentBuild.spec.chart.spec.sourceRef.name)
const currentManifests = await helmTemplate(currentBuild, currentRepository)

// Generate incoming template from Helm values
const incomingRelease = await helmRelease(IncomingRelease)
const incomingBuild = await kustomizeBuild(path.dirname(IncomingRelease), incomingRelease.metadata.name)
const incomingRepository = await helmRepository(KubernetesDir, incomingBuild.spec.chart.spec.sourceRef.name)
const incomingManifests = await helmTemplate(incomingBuild, incomingRepository)

// Print diff using dyff
const diff = await $`${dyff} --color=off --truecolor=off between --omit-header --ignore-order-changes --detect-kubernetes=true --output=human ${currentManifests} ${incomingManifests}`
echo(diff.stdout.trim())
