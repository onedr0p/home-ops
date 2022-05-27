# Kubernetes

## Full directory structure

* Each top-level directory in the structure below is a Flux [Kustomization](https://fluxcd.io/docs/components/kustomize/kustomization/). Within each Flux Kustomization there are regular kustomizations.
* Directories under the `base` folder are application definitions.
* Directories under the `@environment` folder are namespaced grouped implementations of the application definitions. These are [patched](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/) with kustomize to have env specific values.

```ruby
📁 kubernetes          # 0. Kubernetes clusters defined as code
├─📁 clusters          # 1. Flux installation directory per env
│ ├─📁 @environment      # 1a. Env flux installations
│ └─📁 settings          # 1b. Cluster wide settings
├─📁 crds              # 2. Custom Resources Definitions
│ ├─📁 base              # 2a. CRDs definitions
│ └─📁 @environment      # 2b. Env CRDs choosen from base
├─📁 charts            # 3. Helm Repositories
│ ├─📁 base              # 3a. Helm Repositories definitions
│ └─📁 @environment      # 3b. Env Helm Repositories choosen from base
├─📁 settings          # 4. Cluster settings and secrets
│ └─📁 @environment      # 4a. Env settings and secrets
├─📁 core              # 5. Core apps that must be loaded prior to apps
│ ├─📁 base              # 5a. Core app definitions
│ └─📁 @environment      # 5b. Env core apps choosen from base, grouped by namespace
├─📁 apps              # 6. Applications that depend on crds, charts & core
│ ├─📁 base              # 6a. App definitions
│ └─📁 @environment      # 6b. Env apps choosen from base, grouped by namespace
└─📁 bootstrap         # Bootstrap Kustomization which is only used to deploy Flux
```

## Kustomization directory structure

This directory structure has the same meaning for `apps`, `charts`, `core` and `crds`. Since there is no need for a `base` folder in `settings` it has been omitted.

```sh
📁 kubernetes
└─📁 apps
  ├─📁 base             # 1. App definitions
  │ └─📁 external-dns   # 2. Definition of the external-dns app
  └─📁 production       # 3. Deploy in the Production cluster
    └─📁 networking     # 4. Deploy in the networking namespace
      └─📁 external-dns # 5. Implementation of external-dns definitions
                          # 5a. Patching with kustomize is required for env specific values
```
