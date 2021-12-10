# DNS

{% import 'links.jinja2' as links %}

My DNS setup may seem a bit complicated at first, but it allows for completely automatic management of DNS entries for service and ingress objects. It also allows for me to determine what ingresses I want public or private.

## Components

### NGINX Ingress Controller

{{ links.external('ingress-nginx') }} is my cluster ingress controller. With {{ links.external('calico') }} in BGP mode, it is set to an `externalIPs` so that I can forward a port on my router directly to the service. If using {{ links.external('metallb') }} I would be using an `loadbalancerIP` instead.

### CoreDNS with k8s_gateway

{{ links.external('coredns') }} is running on my {{ links.external('opnsense') }} router. I have included the {{ links.external('coredns_k8s_gateway') }} plugin so that it can directly connect to my cluster and automatically serve DNS for all my ingresses.

### external-dns

{{ links.external('external-dns') }} runs in my cluster and is connected to Cloudflare. When an ingress has the `external-dns/is-public: "true"` annotation set external-dns will add, update or delete that record in Cloudflare automatically

### Dynamic DNS

My home IP can change at any given time and in order to keep my WAN IP address up to date on Cloudflare I have deployed a CronJob ({{ links.repoUrl('link', 'blob/main/cluster/apps/networking/cloudflare-ddns') }}). This runs in my cluster and periodically checks and updates my `A` record of `ipv4.domain.tld`

## How it all works together

When I am connected to my home network, my DNS server is set to {{ links.external('blocky') }}. I have configured this to forward all requests for my own domain names to the {{ links.external('coredns') }} instance that is running on my router. If an ingress or service exists for the requested address, {{ links.external('coredns_k8s_gateway') }} will respond with the IP address that it received from my cluster. If it doesn't exist, it will respond with `NXDOMAIN`.

When I am outside my home network, I will probably use whatever DNS is provided to me. When I request an address for one of my domains, it will query my domains DNS server and will respond with the DNS record that was set by {{ links.external('external-dns') }}.
