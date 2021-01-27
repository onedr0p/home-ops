FROM ubuntu:focal

ENV DEBIAN_FRONTEND=noninteractive \
    DEBCONF_NONINTERACTIVE_SEEN=true

RUN apt-get -qq update \
    && apt-get install -qqy --no-install-recommends \
        ca-certificates \
        cpio \
        dos2unix \
        fakeroot \
        genisoimage \
        git \
        gzip \
        isolinux \
        p7zip-full \
        pwgen \
        curl \
        whois \
        xorriso \
    && apt autoremove -y \
    && apt clean \
    && rm -rf \
        /tmp/* \
        /var/lib/apt/lists/* \
        /var/cache/apt/* \
        /var/tmp/*

COPY master-nodes.yaml autoinstall-masters.yml
COPY worker-nodes.yaml autoinstall-workers.yml
COPY entrypoint.sh .

RUN mkdir -p /build
VOLUME [ "/build" ]

ENTRYPOINT ["/entrypoint.sh"]
