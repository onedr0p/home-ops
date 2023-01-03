# YAML Madness

YAML aliases, anchors and overrides are a great way to keep your manifests DRY (**D**o not **R**epeat **Y**ourself) but only on a very basic level.

## Anchors and Aliases

```admonish note
The anchor operator **&** is a way to define a variable and the alias character **\*** is a way to reference the value defined in the anchor.
```

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: &app "awesome-app"
  namespace: default
  labels:
    app.kubernetes.io/name: *app
```

_this will be rendered out to..._

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: awesome-app
  namespace: default
  labels:
    app.kubernetes.io/name: "awesome-app"
```

## Overrides

```admonish note
The **<<** operator allows referencing a block of YAML as many times as needed.
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: &app "awesome-app"
  namespace: default
  labels: &labels
    app.kubernetes.io/instance: *app
    app.kubernetes.io/name: *app
spec:
  selector:
    matchLabels:
      <<: *labels
```

_this will be rendered out to..._

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: "awesome-app"
  namespace: default
  labels:
    app.kubernetes.io/instance: "awesome-app"
    app.kubernetes.io/name: "awesome-app"
spec:
  selector:
    matchLabels:
      app.kubernetes.io/instance: "awesome-app"
      app.kubernetes.io/name: "awesome-app"
```

## Important Notes

* Defining an anchor, alias or override cannot be referenced in separate YAML docs whether it is in the same file or not.
* You absolutely cannot concat, or do any advanced string functions on anchors, aliases or overrides.
* Try to make sure your YAML is comprehensible, don't get hung up on making DRY an absolute rule to follow.
