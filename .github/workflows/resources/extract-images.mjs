#!/usr/bin/env zx
$.verbose = false

/**
 * * extract-images.mjs
 * * Extracts all container images from a HelmRelease and renders them as a JSON object
 * @param --helmrelease    : The source Flux HelmRelease to compare against the target
 * @param --kubernetes-dir : The directory containing your Flux manifests including the HelmRepository manifests
 */
const HelmRelease   = argv['helmrelease']
const KubernetesDir = argv['kubernetes-dir']

const helm      = await which('helm')
const kustomize = await which('kustomize')

function extractImageValues(data) {
  const imageValues = [];
  function extractValues(obj) {
    for (const key in obj) {
      if (typeof obj[key] === 'object') {
        extractValues(obj[key]);
      } else if (key === 'image') {
        imageValues.push(obj[key]);
      }
    }
  }
  extractValues(data);
  return imageValues;
}

async function parseHelmRelease(releaseFile) {
  const helmRelease = await fs.readFile(releaseFile, 'utf8')
  const doc = YAML.parseAllDocuments(helmRelease).map((item) => item.toJS())
  const release = doc.filter((item) =>
    item.apiVersion === 'helm.toolkit.fluxcd.io/v2beta2'
      && item.kind === 'HelmRelease'
  )
  return release[0]
}

async function parseHelmRepository(kubernetesDir, releaseName) {
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

async function renderKustomize(releaseBaseDir, releaseName) {
  const build = await $`${kustomize} build --load-restrictor=LoadRestrictionsNone ${releaseBaseDir}`
  const docs = YAML.parseAllDocuments(build.stdout).map((item) => item.toJS())
  const release = docs.filter((item) =>
    item.apiVersion === 'helm.toolkit.fluxcd.io/v2beta2'
      && item.kind === 'HelmRelease'
        && item.metadata.name === releaseName
  )
  return release[0]
}

async function helmTemplate(release, repository) {
  const values = new YAML.Document()
  values.contents = release.spec.values
  const valuesFile = await $`mktemp`
  await fs.writeFile(valuesFile.stdout.trim(), values.toString())

  // Template out helm values into Kubernetes manifests
  let manifests
  if ('type' in repository.spec && repository.spec.type == 'oci') {
    manifests = await $`${helm} template --kube-version 1.28.0 --release-name ${release.metadata.name} --include-crds=false ${repository.spec.url}/${release.spec.chart.spec.chart} --version ${release.spec.chart.spec.version} --values ${valuesFile.stdout.trim()}`
  } else {
    await $`${helm} repo add ${release.spec.chart.spec.sourceRef.name} ${repository.spec.url}`
    manifests = await $`${helm} template --kube-version 1.28.0 --release-name ${release.metadata.name} --include-crds=false ${release.spec.chart.spec.sourceRef.name}/${release.spec.chart.spec.chart} --version ${release.spec.chart.spec.version} --values ${valuesFile.stdout.trim()}`
  }

  let documents = YAML.parseAllDocuments(manifests.stdout.trim()).map((item) => item.toJS())

  const images = [];
  documents.forEach((doc) => {
    const docImageValues = extractImageValues(doc);
    images.push(...docImageValues);
  });
  return images;
}

const helmRelease    = await parseHelmRelease(HelmRelease)
const kustomizeBuild = await renderKustomize(path.dirname(HelmRelease), helmRelease.metadata.name)
const helmRepository = await parseHelmRepository(KubernetesDir, kustomizeBuild.spec.chart.spec.sourceRef.name)
const images         = await helmTemplate(kustomizeBuild, helmRepository)

echo(JSON.stringify(images))
