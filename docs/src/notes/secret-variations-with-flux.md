# Secret variations with Flux

There are several different ways to utilize Kubernetes secrets when using <ins>[Flux](https://fluxcd.io/)</ins> and <ins>[SOPS](https://github.com/mozilla/sops)</ins>, here’s a breakdown of some common methods.

_I will not be covering how to integrate SOPS into Flux for that be sure to check out the <ins>[Flux documentation on integrating SOPS](https://fluxcd.io/docs/guides/mozilla-sops/)</ins>_

## Example Secret

```admonish info
The three following methods will use this secret as an example.
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: application-secret
  namespace: default
stringData:
  AWESOME_SECRET: "SUPER SECRET VALUE"
```

### Method 1: `envFrom`

> _Use `envFrom` in a deployment or a Helm chart that supports the setting, this will pass all secret items from the secret into the containers environment._

```yaml
envFrom:
  - secretRef:
      name: application-secret
```

```admonish example
View example <ins>[Helm Release](https://ln.devbu.io/ngLju)</ins> and corresponding <ins>[Secret](https://ln.devbu.io/ULgnl)</ins>.
```

### Method 2: `env.valueFrom`

> _Similar to the above but it's possible with `env` to pick an item from a secret._

```yaml
env:
  - name: WAY_COOLER_ENV_VARIABLE
    valueFrom:
      secretKeyRef:
        name: application-secret
        key: AWESOME_SECRET
```

```admonish example
View example <ins>[Helm Release](https://ln.devbu.io/0lbMT)</ins> and corresponding <ins>[Secret](https://ln.devbu.io/KYjhP)</ins>.
```

### Method 3: `spec.valuesFrom`

> _The Flux HelmRelease option `valuesFrom` can inject a secret item into the Helm values of a `HelmRelease`_
> * _Does not work with merging array values_
> * _Care needed with keys that contain dot notation in the name_

```yaml
valuesFrom:
  - targetPath: config."admin\.password"
    kind: Secret
    name: application-secret
    valuesKey: AWESOME_SECRET
```

```admonish example
View example <ins>[Helm Release](https://ln.devbu.io/ARdun)</ins> and corresponding <ins>[Secret](https://ln.devbu.io/hNef8)</ins>.
```

### Method 4: Variable Substitution with Flux

> _Flux variable substitution can inject secrets into any YAML manifest. This requires the <ins>[Flux Kustomization](https://fluxcd.io/docs/components/kustomize/kustomization/)</ins> configured to enable <ins>[variable substitution](https://fluxcd.io/docs/components/kustomize/kustomization/#variable-substitution)</ins>. Correctly configured this allows you to use `${GLOBAL_AWESOME_SECRET}` in any YAML manifest._

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cluster-secrets
  namespace: flux-system
stringData:
  GLOBAL_AWESOME_SECRET: "GLOBAL SUPER SECRET VALUE"
```

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
# ...
spec:
# ...
  decryption:
    provider: sops
    secretRef:
      name: sops-age
  postBuild:
    substituteFrom:
      - kind: Secret
        name: cluster-secrets
```

```admonish example
View example <ins>[Fluxtomization](https://ln.devbu.io/ZMbfI)</ins>, <ins>[Helm Release](https://ln.devbu.io/y6DJS)</ins>, and corresponding <ins>[Secret](https://ln.devbu.io/kRoHj)</ins>.
```

## Final Thoughts

* For the first **three methods** consider using a tool like <ins>[stakater/reloader](https://github.com/stakater/Reloader)</ins> to restart the pod when the secret changes.

* Using reloader on a pod using a secret provided by Flux Variable Substitution will lead to pods being restarted during any change to the secret while related to the pod or not.

* The last method should be used when all other methods are not an option, or used when you have a “global” secret used by a bunch of YAML manifests.
