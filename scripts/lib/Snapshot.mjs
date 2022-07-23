import { argv, $, YAML } from 'zx'

class Snapshot {
  constructor (arg) {
    this.arg = arg
    this.help = argv.help || false
    this.app = argv.app || argv.a || process.env.APP
    this.namespace = argv.namespace || argv.n || process.env.NAMESPACE
    this.kopiaApp = argv['kopia-app'] || process.env.KOPIA_APP || 'kopia'
    this.kopiaNamespace = argv['kopia-namespace'] || process.env.KOPIA_NAMESPACE || 'default'

    if (!this.app) {
      throw new Error('Argument --app, -a or env APP not set')
    }
    if (!this.namespace) {
      throw new Error('Argument --namespace, -n or env NAMESPACE not set')
    }

    switch (this.arg) {
      case 'list':
        this.list()
        break
      case 'create':
        this.create()
        break
      default:
        throw new Error(`404: ${arg} arg not found`)
    }
  }

  async list () {
    if (this.help) {
      console.log('Usage: ctl snapshot list --app <app> --namespace <namespace> --kopia-app <kopia-app> --kopia-namespace <kopia-namespace>')
      return process.exit(0)
    }

    const snapshots = await $`kubectl -n ${this.kopiaNamespace} exec -it deployment/${this.kopiaApp} -- kopia snapshot list /data/${this.namespace}/${this.app} --json`
    const structData = []
    for (const obj of JSON.parse(snapshots.stdout)) {
      const latest = obj.retentionReason.includes('latest-1')
      structData.push({
        'snapshot id': obj.id,
        'date created': obj.startTime,
        latest
      })
    }
    console.table(structData)
  }

  async create () {
    if (this.help) {
      console.log('Usage: ctl snapshot create --app <app> --namespace <namespace>')
      return process.exit(0)
    }
    const jobRaw = await $`kubectl -n ${this.namespace} create job --from=cronjob/${this.app}-snapshot ${this.app}-snapshot-${+new Date()} --dry-run=client --output json`
    const jobJson = JSON.parse(jobRaw.stdout)
    delete jobJson.spec.template.spec.initContainers
    const jobYaml = new YAML.Document()
    jobYaml.contents = jobJson
    await $`echo ${jobYaml.toString()}`.pipe($`kubectl apply -f -`)
  }
}

export { Snapshot }
