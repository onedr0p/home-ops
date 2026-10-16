# Rendering a HelmRelease with flate

When a chart version or a HelmRelease's values change, render the
HelmRelease with this repository's values, from the repository root, with
the namespace's directory as the path.

With git history, diff it against the base, which flate renders from that
revision in a temporary directory:

```
flate diff hr <name> --base origin/main --path kubernetes/apps/<namespace> --no-progress -o diff
```

Without history, as in kritika's checkout, build the head alone:

```
flate build hr <name> --path kubernetes/apps/<namespace> --no-progress
```

A HelmRelease whose Kustomization depends on one in another namespace is
reported as blocked there; render it from the whole tree instead, which
takes several times the memory:

```
flate build hr <name> -n <namespace> --path kubernetes/apps --no-progress
```

flate reports every failure in the namespace, not only the requested
HelmRelease's, and exits nonzero for any of them. A failure is a finding
on the changed line only when it belongs to the HelmRelease under review
and the change caused it: a value the chart's schema rejects, a template
that errors on this repository's values. A failure of another
HelmRelease, or a source that could not be fetched, says nothing about the
change.

A render that succeeds is an offline approximation of what the cluster
applies: CRDs and Secrets are left out, patches Flux applies from a parent
Kustomization are not, and templates that branch on Kubernetes
capabilities see flate's bundled version, not the cluster's. Within that,
take the label values, resource names and ports the search for
dependents needs from the render rather than from a reading of the template,
and narrow it with `--show-only <template path>` when the whole output is
too long. Where only the head renders, what the base produced is read
upstream, or from the names this repository already refers to.
