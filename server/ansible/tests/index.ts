import * as digitalocean from "@pulumi/digitalocean";
import * as pulumi from "@pulumi/pulumi";

const region = digitalocean.Regions.SFO3;

const dropletControlTypeTag = new digitalocean.Tag(`ansible-control-${pulumi.getStack()}`);
const dropletGenericTypeTag = new digitalocean.Tag(`ansible-generic-${pulumi.getStack()}`);

const dropletControlCount = 1;
const dropletGenericCount = 2;

// Create 'master' nodes
const controlDroplets = [];
for (let i = 0; i < dropletControlCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-control-node-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    controlDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS1VCPU1GB,
        tags: [nameTag.id, dropletControlTypeTag.id],
        sshKeys: ["29649448", "29653368"],
    }));
}

// Create 'worker' nodes
const genericDroplets = [];
for (let i = 0; i < dropletGenericCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-generic-node-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    genericDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS1VCPU1GB,
        tags: [nameTag.id, dropletGenericTypeTag.id],
        sshKeys: ["29649448", "29653368"],
    }));
}

// Create Load Balancer for the Kubernetes API
const kubernetesLoadBalancer = new digitalocean.LoadBalancer("kubernetes-public", {
    dropletTag: dropletControlTypeTag.name,
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
    dropletTag: dropletGenericTypeTag.name,
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
        "control-nodes": {
            hosts: {
                "k8s-control-node-a": {
                    "ansible_host": controlDroplets[0].ipv4Address,
                    "ansible_user": "root",
                    "k3s_control_node_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": controlDroplets[0].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                }
            },
        },
        "generic-nodes": {
            hosts: {
                "k8s-generic-node-a": {
                    "ansible_host": genericDroplets[0].ipv4Address,
                    "ansible_user": "root",
                    "k3s_control_node_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": genericDroplets[0].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                },
                "k8s-generic-node-b": {
                    "ansible_host": genericDroplets[1].ipv4Address,
                    "ansible_user": "root",
                    "k3s_control_node_address": kubernetesLoadBalancer.ip,
                    "digitalocean_private_ip": genericDroplets[1].ipv4AddressPrivate,
                    "digitalocean_http_ip": httpLoadBalancer.ip,
                }
            },
        },
    },
}
