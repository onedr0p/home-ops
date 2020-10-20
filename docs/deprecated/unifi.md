# unifi

Provision the USG to sync my home IP address to my Cloudflare domain and force DNS requests to use Blocky

## config.gateway.json

Read more about how to apply changes to `config.gateway.json` from the following links:

- [USG Advanced Configuration](https://help.ubnt.com/hc/en-us/articles/215458888-UniFi-USG-Advanced-Configuration)
- [Where is Unifi base?](https://help.ubnt.com/hc/en-us/articles/115004872967)

In [config.gateway-example.json](../docs/config.gateway-example.json) make sure you use your `WAN` interface for the `dns` section and for the `nat` section use your USGs `LAN` interface. SSH into each device to make sure you choose the right device by looking at their interfaces.
