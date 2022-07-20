// const PROJECT_ROOT = process.env.PWD;
// const GITHUB_TOKEN = process.env.TOKEN

// const APP             = argv["app"] || argv["a"] || process.env.APP
// const NAMESPACE       = argv["namespace"] || argv["n"] || process.env.NAMESPACE

class Snapshot {

    constructor(debug = false, help = false) {
        this.debug           = debug
        this.help            = help
        this.app             = argv["app"] || argv["a"] || process.env.APP
        this.namespace       = argv["namespace"] || argv["n"] || process.env.NAMESPACE
        this.kopiaApp        = argv["kopia-app"] || process.env.KOPIA_APP || "kopia"
        this.kopiaNamespace  = argv["kopia-namespace"] || process.env.KOPIA_NAMESPACE || "default"

        if (this.debug) {
            $.verbose = true
        }
    }

    async List() {
        if (this.help) {
            console.log(`Usage: ctl snapshot list --app <app> --namespace <namespace> --kopia-app <kopia-app> --kopia-namespace <kopia-namespace>`)
            process.exit(0);
        }
        if (!this.app)       { throw new Error("Argument --app, -a or env APP not set") }
        if (!this.namespace) { throw new Error("Argument --namespace, -n or env NAMESPACE not set") }
        const snapshots = await $`kubectl -n ${this.kopiaNamespace} exec -it deployment/${this.kopiaApp} -- kopia snapshot list /data/${this.namespace}/${this.app} --json`
        let structData = []
        for (const obj of JSON.parse(snapshots.stdout)) {
            const latest = obj.retentionReason.includes("latest-1")
            structData.push({ "snapshot id": obj.id, "date created": obj.startTime, latest: latest })
        }
        console.table(structData);
    }

    async Create() {
        if (this.help) {
            console.log(`Usage: ctl snapshot create --app <app> --namespace <namespace>`)
            process.exit(0);
        }
        const jobRaw = await $`kubectl -n ${this.namespace} create job --from=cronjob/${this.app}-snapshot ${this.app}-snapshot-${+new Date} --dry-run=client --output json`
        const jobJson = JSON.parse(jobRaw.stdout)
        delete jobJson.spec.template.spec.initContainers
        const jobYaml = new YAML.Document();
        jobYaml.contents = jobJson;
        await $`echo ${jobYaml.toString()}`.pipe($`kubectl apply -f -`)
    }
}

export { Snapshot }
