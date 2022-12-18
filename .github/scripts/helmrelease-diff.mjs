#!/usr/bin/env zx
$.verbose = false
const HelmReleaseName = argv['helm-release-name']
const KustomizeBaseDir = argv['kustomize-base-dir']
const HelmRepositoryDir = argv['helm-repository-dir']

async function helmRelease(base, name) {
  const build = await $`kustomize build --load-restrictor=LoadRestrictionsNone ${base}`
  const docs = YAML.parseAllDocuments(build.stdout).map((item) => item.toJS());
  const release = docs.filter((item) =>
    item.apiVersion === 'helm.toolkit.fluxcd.io/v2beta1'
      && item.kind === 'HelmRelease'
        && item.metadata.name === name
  )
  return release[0]
}

async function helmRepositoryUrl (repositoryName) {
  const build = await $`kustomize build --load-restrictor=LoadRestrictionsNone ${HelmRepositoryDir}`
  const docs = YAML.parseAllDocuments(build.stdout).map((item) => item.toJS());
  const repo = docs.filter((item) =>
    item.apiVersion === 'source.toolkit.fluxcd.io/v1beta2'
      && item.kind === 'HelmRepository'
        && item.metadata.name === repositoryName
  )
  return repo[0].spec.url
}

async function helmRepoAdd (name, url) {
  await $`helm repo add ${name} ${url}`
}

async function helmTemplate (releaseName, repositoryName, chartName, chartVersion, chartValues) {
  const values = new YAML.Document();
  values.contents = chartValues;
  const valuesFile = await $`mktemp`
  await fs.writeFile(valuesFile.stdout.trim(), values.toString());

  const manifestsFile = await $`mktemp`
  const manifests = await $`helm template --kube-version 1.24.8 --release-name ${releaseName} --skip-crds ${repositoryName}/${chartName} --version ${chartVersion} --values ${valuesFile.stdout.trim()}`
  await fs.writeFile(manifestsFile.stdout.trim(), manifests.stdout.trim());

  return manifestsFile.stdout.trim()
}

const release = await helmRelease(KustomizeBaseDir, HelmReleaseName);
const repositoryUrl = await helmRepositoryUrl(release.spec.chart.spec.sourceRef.name)
await helmRepoAdd(release.spec.chart.spec.sourceRef.name, repositoryUrl)
const manifests = await helmTemplate(
  release.metadata.name,
  release.spec.chart.spec.sourceRef.name,
  release.spec.chart.spec.chart,
  release.spec.chart.spec.version,
  release.spec.values
)
echo(manifests)
