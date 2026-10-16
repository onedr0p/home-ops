# Reading a registry with crane

When `crane` is available, use it rather than `curl` for a container image
or an OCI chart. It reads registries anonymously and prints JSON.

- `crane ls <registry>/<repo>` lists tags. `sha256-…` tags are signatures
  and attestations, not versions.
- `crane digest <image>:<tag>` resolves a tag to its digest.
- `crane manifest <image>:<tag>` shows a multi-platform image's platforms.
  The cluster's nodes are all `linux/amd64`; a new tag without it is a
  finding.
- `crane config --platform linux/amd64 <image>@<digest>` shows when the
  image was built (`created`) and its labels:
  `org.opencontainers.image.source` names the upstream project, and
  `org.opencontainers.image.revision` the commit the image was built from.
  On `ghcr.io/home-operations/*` images that is a
  `home-operations/containers` commit, not the app's: its diff says why a
  digest-only update was rebuilt.
- `crane config <chart>:<version>` on an `OCIRepository` chart prints its
  `Chart.yaml` as JSON: `version`, `appVersion` and `sources`, at the old
  and the new tag.
