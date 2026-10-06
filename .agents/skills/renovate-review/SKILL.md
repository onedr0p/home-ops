---
name: renovate-review
description: Review a Renovate dependency update in this Flux repository. Where to find a dependency's upstream history (charts from their OCIRepository, images, actions, mise tools), what counts as a breaking change, how to check what under kubernetes/ depends on it, and where this repository's Renovate rules live. Read it for any pull request on a renovate/ branch.
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

- An image at `<registry>/<owner>/<repo>` usually comes from `<owner>/<repo>`
  on GitHub; otherwise the body or the image's
  `org.opencontainers.image.source` annotation names the source.
- A chart's source is the app's `OCIRepository` (`ocirepository.yaml`): its
  `url` is the registry path and `ref.tag` the version. A path under an
  owner (`oci://<registry>/<owner>/...`) is that owner's chart on GitHub,
  where `Chart.yaml`'s `sources` or `home` confirms the repository. A path
  that begins with a hostname (`oci://<proxy>/<host>/<path>/<chart>`) is a
  proxy of the Helm repository at `https://<host>/<path>`; find that
  project's GitHub repository and read its `CHANGELOG.md` or releases
  there. Chart version and app version differ: read the chart's changelog,
  and the application's too when `appVersion` moved.
- A repository that publishes many charts prefixes its release tags with
  the chart name (`<chart>-1.2.3`, not `v1.2.3`). When a release is not
  found, list releases and look for the chart name.
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
anything here depends on it. Search `kubernetes/` for:

- **a label key or value**: whatever selects on it, such as `matchLabels`
  and `selector` fields of monitors, network policies and disruption
  budgets, and label matchers in PromQL rules and dashboards;
- **a resource name**: whatever refers to it, such as route backends,
  cross-namespace DNS (`<name>.<namespace>.svc.cluster.local`), selectors,
  and Flux `dependsOn` and `healthChecks`;
- **a value, flag or CRD field**: the HelmRelease `values`, `valuesFrom`,
  `postRenderers`, kustomize patches, and the custom resources other apps
  create from the dependency's CRDs (`apiVersion: <group>`).

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
- `.renovaterc.json5` is the source for how Renovate treats this update:
  its `automerge` rules say whether the PR merges on its own, in which case
  the review is the last look before the merge; its `groupName` rules say
  which PRs move several packages at once, each of which the review
  covers; its labels and the shared preset's `!` on a major update should
  agree with the title, and drift between them is worth a note.
- Secrets are ExternalSecrets from 1Password: judge key names and mappings
  from the manifests.
