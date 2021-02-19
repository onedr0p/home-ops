import * as digitalocean from "@pulumi/digitalocean";
import * as pulumi from "@pulumi/pulumi";

const dropletCount = 3;
const region = digitalocean.Regions.NYC3;

const dropletTypeTag = new digitalocean.Tag(`demo-app-${pulumi.getStack()}`);

const droplets = [];
for (let i = 0; i < dropletCount; i++) {
    const nameTag = new digitalocean.Tag(`web-${i}`);
    droplets.push(new digitalocean.Droplet(`web-${i}`, {
        image: "ubuntu-20-10-x64",
        region: region,
        privateNetworking: true,
        size: digitalocean.DropletSlugs.DropletS1VCPU2GB,
        tags: [nameTag.id, dropletTypeTag.id],
        sshKeys: ["29649448"],
    }));
}

export const ip1 = droplets[0].ipv4Address;
export const ip2 = droplets[1].ipv4Address;
export const ip3 = droplets[3].ipv4Address;
