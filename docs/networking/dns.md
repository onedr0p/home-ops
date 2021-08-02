# DNS

{% import 'links.jinja2' as links %}

My DNS setup may seem a bit complicated at first, but it allows for completely automatic management of DNS entries for Services and Ingress objects.

## Components

### Traefik

{{ links.external('traefik') }} is my cluster Ingress controller. It is set to a `externalIPs` so that I can forward a port on my router directly to the Service.

### CoreDNS with k8s_gateway

{{ links.external('coredns') }} is running on my {{ links.external('opnsense') }} router. I have included the {{ links.external('coredns_k8s_gateway') }} plugin so that I can connect it directly to my cluster.

### external-dns

{{ links.external('external-dns') }} runs in my cluster and is connected to my domains DNS server. It automatically manages records for all my Ingresses that have the `external-dns/is-public: "true"` annotation set.

### Dynamic DNS

In order to keep my WAN IP address up to date on my DNS provider I have deployed a CronJob ({{ links.repoUrl('link', 'blob/main/cluster/apps/networking/cloudflare-ddns/cron-job.yaml') }}) in my cluster that periodically checks and updates those records.

## How it all works together

When I am connected to my home network, my DNS server is set to {{ links.external('blocky') }}. I have configured this to forward all requests for my own domain names to the {{ links.external('coredns') }} instance that is running on my router. If an Ingress or Service exists for the requested address, {{ links.external('coredns_k8s_gateway') }} will respond with the IP address that it received from my cluster. If it doesn't exist, it will respond with `NXDOMAIN`.

When I am outside my home network, I will probably use whatever DNS is provided to me. When I request an address for one of my domains, it will query my domains DNS server and will respond with the DNS record that was set by {{ links.external('external-dns') }}.
