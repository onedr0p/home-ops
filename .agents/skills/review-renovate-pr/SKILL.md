---
name: review-renovate-pr
description: Review a Renovate dependency update in this Flux repository. Where to find each dependency's upstream history (OCIRepository charts through ghcr.io or the ocharted proxy, images, actions, mise tools), what counts as a breaking change, what under kubernetes/ to check for exposure to it, and this repository's auto-merge and grouping rules. Read it for any pull request on a renovate/ branch.
---

# Review a Renovate PR

Judge whether the update is safe to merge: what changed upstream between the
old and new versions, and whether anything in this repository depends on
it. Only `github.com`, `api.github.com` and `raw.githubusercontent.com` are
reachable; doc sites, Artifact Hub and chart registries are not.

## The update

Take from the title, body, labels and diff: the package and its datasource
(container image, Helm chart as an `OCIRepository`, GitHub Action, mise
tool, Grafana dashboard, Renovate preset), the old and new version or
digest, the update type from the `type/*` label, and the changed files,
which are the call sites that consume the dependency.

Renovate's body carries a collapsed **Release Notes** section with upstream
excerpts. Read it first. Go upstream when it is missing, truncated or
ambiguous, and always for a major update or a jump over several versions:
read every intermediate release, breaking changes land in the middle.

## Finding the upstream

- `ghcr.io/<owner>/<repo>` images come from `<owner>/<repo>` on GitHub; for
  other images, the body or the image's `org.opencontainers.image.source`
  annotation names the source.
- `oci://ghcr.io/home-operations/charts/<chart>` is the home-operations
  fleet's own chart; its releases are in `home-operations/<chart>`.
- `oci://ocharted.turbo.ac/<host>/<path>/<chart>` is a proxy of the Helm
  repository at `https://<host>/<path>`; find that project's GitHub
  repository and read its `CHANGELOG.md` or releases there. Chart version
  and app version differ: read the chart's changelog, and the
  application's too when `appVersion` moved.
- Multi-chart repositories (`prometheus-community/helm-charts`,
  `VictoriaMetrics/helm-charts`, `bitnami/charts`) prefix release tags with
  the chart name: `kube-prometheus-stack-75.0.0`, not `v75.0.0`. When a
  release is not found, list releases and look for the chart name.
- A digest-only update moved no version: say whether the tag was rebuilt
  (a security rebuild or a `latest`-style pin).
- A release note that says "see #2785" is read with `gh issue view` or
  `gh pr view`, and an issue is taken to the merged PR that closed it
  (`gh pr list -R <repo> --search "#<n>" --state merged`): the PR says what
  changed and in what scope, where the issue and the note may not.

## What breaks

Flag in each release: `BREAKING CHANGE`, `⚠` or `!:` markers; removed or
renamed Helm values, CRD fields, environment variables and flags; a
required Kubernetes, Flux or Talos version; one-way schema or data
migrations; changed defaults (authentication, storage class, ports,
probes); deprecations that became errors; new required keys with no
default; and label values that changed while the key stayed, or resource
names that dropped or gained a prefix, which break anything selecting on
the old value while a search for the key still matches.

Minor and patch updates carry breaking changes too. "Chart name prefix
removed" is ambiguous between label values and resource names: settle it
from the PR or the template, not the sentence.

## Exposure here

The question is not whether this repository sets the old thing but whether
anything here depends on it:

- **Label key or value**: what selects on the old one under `kubernetes/`:
  `matchLabels`, `selector`, `labelSelector`, `jobLabel` in ServiceMonitor,
  PodMonitor and PrometheusRule objects, and PromQL in rules and dashboards.
- **Resource name**: references to the old name: `HTTPRoute` `backendRefs`,
  ServiceMonitor selectors, cross-namespace DNS
  (`<name>.<namespace>.svc.cluster.local`), NetworkPolicy selectors,
  `dependsOn` and `healthChecks` in `ks.yaml`.
- **Value, flag or CRD field**: the HelmRelease `values`, `valuesFrom`,
  `postRenderers`, kustomize patches, and the CRD objects other apps create
  (`apiVersion: <group>`).

Before prescribing a rename or a new value, confirm it from the upstream
PR's diff or from the chart's template at the new tag, read raw with
`gh api -H "Accept: application/vnd.github.raw+json" repos/<owner>/<repo>/contents/<path>?ref=<tag>`.
Without that, make it a check to do after the merge rather than an edit; a
wrong edit that gets applied is worse than none.

A finding anchors to the bumped line in the diff; name the dependent file
and line in its explanation. A breaking change that touches nothing here
is not a finding: one sentence in the take, with the search that came up
empty, is enough.

## This repository

- Flux reconciles `kubernetes/` from `main`: a merge rolls out within
  minutes.
- Renovate auto-merges some updates (`.renovaterc.json5`): digests of
  `home-operations` images; minor and patch updates of
  `kube-prometheus-stack`, weekly; minor, patch and digest updates of
  GitHub Actions; Grafana dashboards; Renovate presets. For those the
  review is the last look before the merge.
- Grouped PRs (`actions-runner-controller`, `flux-operator`, `kubernetes`,
  `rook-ceph`, `talos`, `mise tools`) move several packages at once; cover
  each.
- Secrets are ExternalSecrets from 1Password: judge key names and mappings
  from the manifests.
- A major update is labelled `type/major` and the shared preset puts a `!`
  in its title; a title that disagrees with its labels is Renovate drift
  worth a note.
