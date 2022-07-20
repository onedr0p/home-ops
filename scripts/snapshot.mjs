#!/usr/bin/env zx

// Usage:
// zx ./scripts/snapshot-list.mjs --app whisparr --namespace default --kopia-namespace default

import { create, list } from './lib/snapshot.mjs';

$.verbose = false

const action = argv["action"] || process.env.ACTION
const app = argv["app"] || process.env.APP
const namespace = argv["namespace"] || process.env.NAMESPACE

if (!app) { throw new Error("Argument --app or envirornment variable APP not set") }
if (!namespace) { throw new Error("Argument --namespace or envirornment variable NAMESPACE not set") }

switch(action) {
  case "create":
    await create(app, namespace)
    break;
  case "list":
    await list(app, namespace)
    break;
  default:
    // code block
}

// const timestamp = +new Date;

// let jobRaw = await $`kubectl -n ${namespace} create job --from=cronjob/${app}-snapshot ${app}-snapshot-${timestamp} --dry-run=client --output json`
// let jobJson = JSON.parse(jobRaw.stdout)
// delete jobJson.spec.template.spec.initContainers

// const jobYaml = new YAML.Document();
// jobYaml.contents = jobJson;

// let jobRun = await $`echo ${jobYaml.toString()}`
//   .pipe($`kubectl apply -f -`)

// console.log(jobYaml.toString())

//  .pipe(`yq eval "del(.spec.template.spec.initContainers)" - `)
//  .pipe(`kubectl apply -f -`)

// let structData = []
// for (const obj of JSON.parse(snapshots.stdout)) {
//   const latest = obj.retentionReason.includes("latest-1")
//   structData.push({ "snapshot id": obj.id, "date created": obj.startTime, latest: latest })
// }

// console.table(structData);

// console.log(JSON.stringify(JSON.parse(snapshots), null, 2))

// const transformed = structData.reduce((acc, {id, ...x}) => { acc[id] = x; return acc}, {})

// kubectl -n {{.NAMESPACE}} create job --from=cronjob/{{.APP}}-snapshot {{.APP}}-snapshot-{{.TS}} --dry-run=client --output yaml \
// | yq eval "del(.spec.template.spec.initContainers)" - \
// | kubectl apply -f -
// - sleep 2
// - kubectl -n {{.NAMESPACE}} wait pod --for condition=ready --selector=job-name={{.APP}}-snapshot-{{.TS}} --timeout={{.TIMEOUT | default "1m"}}
// - kubectl -n {{.NAMESPACE}} logs --selector=job-name={{.APP}}-snapshot-{{.TS}} -f
// - kubectl -n {{.NAMESPACE}} delete job {{.APP}}-snapshot-{{.TS}}
