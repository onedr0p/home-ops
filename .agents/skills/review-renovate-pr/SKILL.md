---
name: review-renovate-pr
description: Review a Renovate dependency update in this Flux repository. Finds what changed upstream between the old and new versions from release notes, changelogs and the PRs behind them, flags breaking changes, and checks whether anything under kubernetes/ depends on what changed (HelmRelease values, selectors, resource names, CRD fields). Read it for any pull request on a renovate/ branch or titled as a Renovate update.
---

# Review a Renovate PR

Give an evidence-backed verdict on whether the update is safe to merge. The
pull request is already in front of you: its title, body, labels and diff.
Start the summary with the verdict, name the sources you read, and report
each breaking change that affects this repository as a finding on the file
and line it affects.

## Tools and reach

- `gh` for everything on GitHub: releases, PRs, issues and file contents
  through `gh api`. Use `--jq` to pick fields; never parse JSON by hand.
- Only `github.com`, `api.github.com` and `raw.githubusercontent.com` are
  reachable. Doc sites, Artifact Hub, chart registries and release assets
  elsewhere are not; read the raw Markdown or template on GitHub instead.
- `helm` is not available. To see what a chart renders, read the specific
  template in the chart's source repository at the new tag with
  `gh api repos/<owner>/<repo>/contents/<path>?ref=<tag> --jq .content | base64 -d`
  or the matching raw.githubusercontent.com URL.
- Search this repository with `rg -n` and `fd`; cite what you find by path
  and line.
- Combine independent calls where you can. Stop searching once a question
  has a definite answer: a fifth empty search for the same thing adds
  nothing.

## Procedure

### 1. Read the update

From the title, body, labels and diff, take the package (`depName`) and its
datasource (container image, Helm chart via OCIRepository, GitHub Action,
mise tool, Grafana dashboard, Renovate preset), `currentValue` to
`newValue` (and the digests when only they moved), the update type from the
`type/*` label, and the changed files, which are the call sites that consume
the dependency.

Renovate's body usually carries a collapsed **Release Notes** section with
upstream excerpts. Read it first; it often has all that is needed. Go
upstream when it is missing, truncated or ambiguous, and always for a major
update or a multi-version jump.

### 2. Fetch the upstream history

- **Container images and GitHub releases**: resolve the source repository.
  `ghcr.io/<owner>/<repo>` is `<owner>/<repo>`; for others use the image's
  `org.opencontainers.image.source` label where the body or the manifest
  shows it. Then `gh release view <tag> -R <owner>/<repo>` for every tag
  after the current version up to and including the new one.
- **Helm charts**: this repository takes charts as `OCIRepository` objects
  (`ocirepository.yaml`, `url: oci://...`). `oci://ghcr.io/<owner>/charts/<chart>`
  comes from `<owner>`'s repository; `oci://ocharted.turbo.ac/<host>/<path>/<chart>`
  is a proxy of the Helm repository at `https://<host>/<path>`, so find that
  project's GitHub repository and read its `CHANGELOG.md` or releases.
  Chart version and app version differ: read the chart's changelog first,
  then the application's when its `appVersion` moved too.
- **GitHub Actions and mise tools**: `gh release list` and `gh release view`
  on the source repository.
- **Digest-only updates**: no version moved; check whether the tag was
  rebuilt (a security rebuild or a `latest`-style pin) and say so.

Multi-chart repositories (`prometheus-community/helm-charts`,
`VictoriaMetrics/helm-charts`, `bitnami/charts`) prefix release tags with
the chart name: `kube-prometheus-stack-75.0.0`, not `v75.0.0`. When a
release is not found, list releases and search for the chart name before
retrying.

Chase references. A release note that says "see #2785" is read with
`gh issue view` or `gh pr view`, and an issue is taken to the merged PR that
closed it (`gh pr list -R <repo> --search "#<n>" --state merged`): the PR
says what actually changed and in what scope, where the issue and the note
may not. For a jump over several versions, walk every intermediate release;
breaking changes land in the middle.

### 3. Flag breaking changes

In each release note or changelog entry, flag:

- explicit `BREAKING CHANGE`, `⚠`, or `!:` markers
- removed or renamed Helm values, CRD fields, environment variables, flags
- a required Kubernetes, Flux or Talos version
- one-way schema or data migrations
- changed defaults (authentication, storage class, ports, probes)
- deprecations that became errors
- new required keys with no default
- label values that changed while the key stayed, and resource names that
  dropped or gained a prefix: a search for the key still matches, and
  anything selecting on the old value breaks silently

Minor and patch updates carry breaking changes too; never skip this step on
semver alone. A note like "chart name prefix removed" is ambiguous between
label values and resource names: settle it from the PR or the template, not
the sentence.

### 4. Check this repository's exposure

The question is not whether this repository sets the old thing, but whether
anything here depends on it. For each breaking change:

- **Label key or value**: search `kubernetes/` for what selects on the old
  key or value: `matchLabels`, `selector`, `labelSelector`, `jobLabel` in
  ServiceMonitor, PodMonitor and PrometheusRule objects, and PromQL in
  rules and dashboards.
- **Resource name**: search for references to the old name: `HTTPRoute`
  `backendRefs`, `ServiceMonitor` selectors, cross-namespace DNS
  (`<name>.<namespace>.svc.cluster.local`), NetworkPolicy selectors,
  `dependsOn` and `healthChecks` in `ks.yaml`.
- **Value, flag or CRD field**: search the HelmRelease `values`, any
  `valuesFrom`, `postRenderers`, kustomize patches, and the CRD objects
  other apps create (`apiVersion: <group>`).

Before prescribing a rename or a new value, confirm it from the chart's
own template at the new tag or from the upstream PR's diff, not from the
release-note text. Without that evidence, make it a post-merge check
("confirm the rendered Service is still named X; httproute.yaml:14 refers
to it") rather than an edit. A wrong edit that gets applied is worse than
none.

A breaking change that touches nothing here is not blocking; say so in one
line with the search that came up empty.

### 5. Write the review

The summary opens with the verdict, one of:

- **Safe to merge**: no breaking change reaches this repository.
- **Review required**: a change reaches it and needs a decision or an edit.
- **Do not merge**: it breaks something here as is; say what must change.

Then the update in one line (`<depName> <current> → <new>`, type and
datasource), the breaking changes with their upstream URLs and their impact
here (a `path:line` or "no impact"), notable non-breaking changes, and the
sources read. Each breaking change with an impact is also a finding on the
affected file and line, so it can be resolved in place. Keep it short: when
nothing breaks and nothing is notable, one line of verdict and the sources
are enough.

## This repository

- Flux reconciles `kubernetes/` from `main`: a merge starts rolling out
  within minutes. Weight "do not merge" accordingly.
- Renovate auto-merges some updates (`.renovaterc.json5`): digests of
  `home-operations` images, minor and patch updates of `kube-prometheus-stack`
  on a weekly schedule, minor, patch and digest updates of GitHub Actions,
  Grafana dashboards and Renovate presets. For those, say whether anything
  should stop the merge; the review is the last look.
- Grouped PRs (`actions-runner-controller`, `flux-operator`, `kubernetes`,
  `rook-ceph`, `talos`, `mise tools`) move several packages at once; cover
  each.
- Charts from `oci://ghcr.io/home-operations/charts/*` are the
  home-operations fleet's own; their release notes live in that
  repository's releases.
- Secrets are ExternalSecrets from 1Password. Judge key names and mappings
  from the manifests; never try to read a value.
- A major update is labelled `type/major` and the shared preset puts a `!`
  in its title; a title that disagrees with its labels is Renovate drift
  worth a note.
