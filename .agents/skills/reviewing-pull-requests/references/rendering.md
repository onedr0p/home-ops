# Rendering a HelmRelease with flate

When a chart version or a HelmRelease's values change, render the
HelmRelease with this repository's values, from the repository root, with
the namespace's directory as the path.

With git history, diff it against the base, which flate renders from that
revision's Git objects:

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

A named render selects the HelmRelease and the inputs it needs. flate
does not render the other HelmReleases in the namespace, and the exit
status covers only that selection. Only a failure the change caused is a
finding on the changed line: a value the chart's schema rejects, a
template that errors on this repository's values. A failed input the
change does not touch, or a source flate failed to fetch, says nothing
about the change.

A render that succeeds is an offline approximation of what the cluster
applies: CRDs and Secrets are left out, patches Flux applies from a parent
Kustomization are not, and templates that branch on Kubernetes
capabilities see flate's bundled version, not the cluster's. Within that,
take the label values, resource names and ports the search for
dependents needs from the render rather than from a reading of the template.
When the whole output is too long, narrow a build with `--only-kinds <kind>`
or filter the rendered YAML. Where only the head renders, what the base
produced is read upstream, or from the names this repository already
refers to.
