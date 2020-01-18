# velero

## Install velero tool locally

```bash
brew install velero
```

## Deploy AWS plugin for velero

After velero has been deployed in your cluster run the following on your local machine

```bash
velero plugin add velero/velero-plugin-for-aws:v1.0.0
```
