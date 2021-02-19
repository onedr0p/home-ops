import * as digitalocean from "@pulumi/digitalocean";
import * as pulumi from "@pulumi/pulumi";
// import * as YAML from 'YAML';
// import * as fs from 'fs';

const region = digitalocean.Regions.NYC3;
const dropletTypeTag = new digitalocean.Tag(`ansible-${pulumi.getStack()}`);

const dropletControlCount = 1;
const dropletGenericCount = 2;

const controlDroplets = [];
for (let i = 0; i < dropletControlCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-control-node-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    controlDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS2VCPU2GB,
        tags: [nameTag.id, dropletTypeTag.id],
        sshKeys: ["29649448"],
    }));
}

const genericDroplets = [];
for (let i = 0; i < dropletGenericCount; i++) {
    const nodeLetter = String.fromCharCode(97 + i);
    const nodeName = `k8s-generic-node-${nodeLetter}`;
    const nameTag = new digitalocean.Tag(`${nodeName}`);
    genericDroplets.push(new digitalocean.Droplet(`${nodeName}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS2VCPU2GB,
        tags: [nameTag.id, dropletTypeTag.id],
        sshKeys: ["29649448"],
    }));
}

export const all = {
    children: {
        "control-nodes": {
            hosts: {
                "k8s-control-node-a": {
                    "ansible_host": controlDroplets[0].ipv4Address,
                    "ansible_user": "root",
                }
            },
        },
        "generic-nodes": {
            hosts: {
                "k8s-generic-node-a": {
                    "ansible_host": genericDroplets[0].ipv4Address,
                    "ansible_user": "root",
                },
                "k8s-generic-node-b": {
                    "ansible_host": genericDroplets[1].ipv4Address,
                    "ansible_user": "root",
                }
            },
        },
    },
}
