const timestamp = +new Date;

async function list(app, namespace) {
    const kopiaApp = argv["kopia-app"] || process.env.KOPIA_APP || "kopia"
    const kopiaNamespace = argv["kopia-namespace"] || process.env.KOPIA_NAMESPACE || "default"
    if (!kopiaApp) { throw new Error("Argument --app or envirornment variable APP not set") }
    if (!kopiaNamespace) { throw new Error("Argument --namespace or envirornment variable NAMESPACE not set") }
    const snapshots = await $`kubectl -n ${kopiaNamespace} exec -it deployment/${kopiaApp} -- kopia snapshot list /data/${namespace}/${app} --json`
    let structData = []
    for (const obj of JSON.parse(snapshots.stdout)) {
        const latest = obj.retentionReason.includes("latest-1")
        structData.push({ "snapshot id": obj.id, "date created": obj.startTime, latest: latest })
    }
    console.table(structData);
}

async function create(app, namespace) {
    const jobRaw = await $`kubectl -n ${namespace} create job --from=cronjob/${app}-snapshot ${app}-snapshot-${timestamp} --dry-run=client --output json`
    const jobJson = JSON.parse(jobRaw.stdout)
    delete jobJson.spec.template.spec.initContainers
    const jobYaml = new YAML.Document();
    jobYaml.contents = jobJson;
    await $`echo ${jobYaml.toString()}`.pipe($`kubectl apply -f -`)
}

export { create, list };
