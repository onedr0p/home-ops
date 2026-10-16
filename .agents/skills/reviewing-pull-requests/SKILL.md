---
name: reviewing-pull-requests
description: Use when reviewing a pull request or Renovate update in this Flux repository, or checking what a change under kubernetes/ affects. Covers finding a dependency's upstream, breaking changes, Renovate's rules here, searching what depends on a change, and what a check proves. references/registry.md reads images and OCI charts with crane; references/rendering.md renders and diffs HelmReleases with flate.
---

# Reviewing pull requests in home-ops

Flux reconciles `kubernetes/` from `main`: a merge rolls out within
minutes. Secrets are ExternalSecrets from 1Password: judge key names and
mappings from the manifests.

Use the sections that fit the pull request: a Renovate update, on a
`renovate/` branch; a change under `kubernetes/`, a Renovate update's
included; what a check proves, for every review; and kritika's account,
when the review runs in kritika.

## A Renovate update

Judge whether the update is safe to merge: what changed upstream between
the old and new versions, and whether anything in this repository depends
on it. GitHub is read with `gh`; a project's own changelog or
documentation site with `curl`; an image or an OCI chart from its
registry with `crane`, when it is available, as `references/registry.md`
describes.

### The update

Take from the title, body, labels and diff: the package and its datasource
(container image, Helm chart as an `OCIRepository`, GitHub Action, mise
tool, Grafana dashboard, Renovate preset), the old and new version or
digest, the update type from the `type/*` label, and the changed files,
which are the call sites that consume the dependency.

Renovate's body carries a collapsed **Release Notes** section with upstream
excerpts. Read it first. Go upstream when it is missing, truncated or
ambiguous, and always for a major update or a jump over several versions:
read every intermediate release, breaking changes land in the middle.

### Finding the upstream

- An image at `<registry>/<owner>/<repo>` usually comes from `<owner>/<repo>`
  on GitHub; otherwise the body or the image's
  `org.opencontainers.image.source` label names the source, read as
  `references/registry.md` describes.
- An image update is checked against the image itself: when `crane` is
  available, read the pinned digest's config as `references/registry.md`
  describes. Its version and revision labels show what it was built from, to
  compare with the release reviewed here.
- A chart's source is the app's `OCIRepository` (`ocirepository.yaml`): its
  `url` is the registry path and `ref.tag` the version. A path under an
  owner (`oci://<registry>/<owner>/...`) is that owner's chart on GitHub,
  where `Chart.yaml`'s `sources` or `home` confirms the repository;
  `crane config` on the chart's tag prints them without a fetch. A path
  under `ghcr.io/home-operations/charts-mirror/<chart>` is a mirror of a
  chart whose project publishes none in OCI form:
  `apps/<chart>/metadata.yaml` in `home-operations/charts-mirror` names the
  upstream Helm repository, and the chart's changelog and releases are in
  that project's own GitHub repository. Chart version and app version
  differ: read the chart's changelog, and the application's too when
  `appVersion` moved.
- A repository that publishes many charts prefixes its release tags with
  the chart name (`<chart>-1.2.3`, not `v1.2.3`). When a release is not
  found, list releases and look for the chart name.
- A digest-only update moved no version: say whether the tag was rebuilt
  (a security rebuild or a `latest`-style pin), and from what: compare the
  old and new digests' `created` and `revision`.
- A release note that says "see #2785" is read with `gh issue view` or
  `gh pr view`, and an issue is taken to the merged PR that closed it
  (`gh pr list -R <repo> --search "#<n>" --state merged`): the PR says what
  changed and in what scope, where the issue and the note may not.

### What breaks

Flag in each release: `BREAKING CHANGE`, `⚠` or `!:` markers; removed or
renamed Helm values, CRD fields, environment variables and flags; a
required Kubernetes, Flux, Talos or kernel version; one-way schema or
data migrations; changed defaults (authentication, storage class, ports,
probes); deprecations that became errors; new required keys with no
default; and label values that changed while the key stayed, or resource
names that dropped or gained a prefix, which break anything selecting on
the old value while a search for the key still matches.

Minor and patch updates carry breaking changes too. "Chart name prefix
removed" is ambiguous between label values and resource names: settle it
from the PR or the template, not the sentence.

An update also moves images that appear nowhere in the diff: a chart or
operator that changes its default images, or stops setting them and
leaves them to another operator's built-in defaults. Name each such image
with its old and new version, read from the chart's or operator's source
at both versions. Nothing here pins them, so Renovate never raises them
and the review is the only place they show. A version a chart sets by
default, such as the image of a workload its operator manages, is the
default in the chart's `values.yaml` at the new tag unless the
HelmRelease values pin it.

For an update under `kubernetes/`, render it and search what depends on it
as [a change under `kubernetes/`](#a-change-under-kubernetes) describes. A
breaking change that touches nothing here is not a finding: one sentence in
the take, with the search that came up empty, is enough.

### Renovate's rules

`.renovaterc.json5` is the source for how Renovate treats this update:
its `automerge` rules say whether the PR merges on its own, in which case
the review is the last look before the merge; its `groupName` rules say
which PRs move several packages at once, each of which the review
covers; its labels and the shared preset's `!` on a major update should
agree with the title, and drift between them is worth a note.

## A change under `kubernetes/`

When a chart version or a HelmRelease's values change, render the
HelmRelease as `references/rendering.md` describes when `flate` is
available.

### Exposure here

The question is not whether this repository sets the old thing but whether
anything here depends on it. Search `kubernetes/` for:

- **a label key or value**: whatever selects on it, such as `matchLabels`
  and `selector` fields of monitors, network policies and disruption
  budgets, and label matchers in PromQL rules and dashboards;
- **a resource name**: whatever refers to it, such as route backends,
  cross-namespace DNS (`<name>.<namespace>.svc.cluster.local`), selectors,
  and Flux `dependsOn` and `healthChecks`;
- **a value, flag or CRD field**: the HelmRelease `values`, `valuesFrom`,
  `postRenderers`, kustomize patches, including those the FluxInstance in
  `kubernetes/apps/flux-system/flux-instance` applies to every HelmRelease
  (a CRD upgrade policy among them), and the custom resources other apps
  create from the dependency's CRDs (`apiVersion: <group>`).

An app configured through its own UI keeps that configuration on its
volume, not in git, so a search of this repository proves nothing about
it: an affected integration or setting there is one the review could not
verify.

Before prescribing a rename or a new value, confirm it from the upstream
PR's diff or from the chart's template at the new tag, read raw with
`gh api -H "Accept: application/vnd.github.raw+json" repos/<owner>/<repo>/contents/<path>?ref=<tag>`.
Without that, make it a check to do after the merge rather than an edit; a
wrong edit that gets applied is worse than none.

A finding anchors to the changed line in the diff; name the dependent
file and line in its explanation.

## What a check proves

- Write an inference out, and only one the evidence carries. A render of
  the new chart that succeeded proves the tag exists and the values fit
  its schema. A default the release changes to a value this repository
  already sets explicitly changes nothing here; a prerequisite that comes
  with it, such as a kernel or Kubernetes version, is checked on its own.
- A version requirement is checked against the version this repository
  targets, read from where it pins it. A target in git is not proof that
  a rollout reached every node: say that the line rests on the target.
- Put the evidence in the claim: the value found and the file it came
  from, or the source that says so. "`auth.enabled: true` already set in
  the HelmRelease values" carries its proof; "auth checked" does not.
- What the repository cannot show is not a check: say what could not be
  verified and what to look at after the merge.

## In kritika

kritika's confidence scorer judges the review by its checked lines and the
sources it lists. It has the description and the diff but no tools: it
never sees the commands the review ran or what they printed, and a
release-note entry that no checked line covers lowers its score.

- For an update, give every entry under the release notes' breaking
  changes and upgrade notes, and every step the upgrade guide names, a
  checked line of its own, including one that touches nothing here: name
  the entry, then why it does not apply or what it changes.

kritika's checkout has no git history, so only the head renders, as
`references/rendering.md` says.
