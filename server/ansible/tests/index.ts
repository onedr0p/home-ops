import * as digitalocean from "@pulumi/digitalocean";
import * as pulumi from "@pulumi/pulumi";

const region = digitalocean.Regions.SFO3;

const dropletMasterTypeTag = new digitalocean.Tag(`ansible-control-${pulumi.getStack()}`);
const dropletWorkerTypeTag = new digitalocean.Tag(`ansible-generic-${pulumi.getStack()}`);

const dropletMasterCount = 1;
const dropletWorkerCount = 1;

// Create 'master' nodes
const masterDroplets = [];
for (let i = 0; i < dropletMasterCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-master-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    masterDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS1VCPU1GB,
        tags: [nameTag.id, dropletMasterTypeTag.id],
        sshKeys: ["29649448", "29653368"],
    }));
}

// Create 'worker' nodes
const workerDroplets = [];
for (let i = 0; i < dropletWorkerCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-worker-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    workerDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS1VCPU1GB,
        tags: [nameTag.id, dropletWorkerTypeTag.id],
        sshKeys: ["29649448", "29653368"],
    }));
}

// Create Load Balancer for the Kubernetes API
const kubernetesLoadBalancer = new digitalocean.LoadBalancer("kubernetes-public", {
    dropletTag: dropletMasterTypeTag.name,
    forwardingRules: [{
        entryPort: 6443,
        entryProtocol: digitalocean.Protocols.HTTPS,
        targetPort: 6443,
        targetProtocol: digitalocean.Protocols.HTTPS,
        tlsPassthrough: true
    }],
    healthcheck: {
        port: 6443,
        protocol: digitalocean.Protocols.TCP,
    },
    region: region,
});

// Create Load Balancer for the NGINX Deployment
const httpLoadBalancer = new digitalocean.LoadBalancer("http-public", {
    dropletTag: dropletWorkerTypeTag.name,
    forwardingRules: [{
        entryPort: 80,
        entryProtocol: digitalocean.Protocols.HTTP,
        targetPort: 30420,
        targetProtocol: digitalocean.Protocols.HTTP,
    }],
    healthcheck: {
        port: 30420,
        protocol: digitalocean.Protocols.TCP,
    },
    region: region,
});

// Export in format interoperable with Ansible
// e.g. using yq@v4 'pulumi stack output --json | yq eval -P - > hosts.yml'
export const all = {
    children: {
        "master-nodes": {
            hosts: {
                "k8s-master-a": {
                    "ansible_host": masterDroplets[0].ipv4Address,
                    "ansible_user": "root",
                    "k3s_registration_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": masterDroplets[0].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                }
            },
        },
        "worker-nodes": {
            hosts: {
                "k8s-worker-a": {
                    "ansible_host": workerDroplets[0].ipv4Address,
                    "ansible_user": "root",
                    "k3s_registration_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": workerDroplets[0].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                },
                "k8s-worker-b": {
                    "ansible_host": workerDroplets[1].ipv4Address,
                    "ansible_user": "root",
                    "k3s_registration_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": workerDroplets[1].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                }
            },
        },
    },
}
