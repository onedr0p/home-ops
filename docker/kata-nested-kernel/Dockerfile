# syntax=docker/dockerfile:1
# Guest kernel for the `kata-qemu-nested` RuntimeClass.
#
# The guest kernel shipped in the siderolabs/kata-containers extension is built
# without KVM host support, so a workload inside a Kata VM has no /dev/kvm even
# though QEMU's `-cpu host` exposes VMX to the guest. This rebuilds that same
# kernel from kata's own shipped .config — stock kernel plus one subsystem —
# with KVM enabled, and carries the matching runtime config that points at it.
#
# Retire this once kata-containers ships a nested-virt guest kernel and the
# Talos extension packages it; see the PR description for the upstream shape.

ARG KATA_VERSION=3.32.0

FROM docker.io/library/debian:trixie-slim AS build
ARG KATA_VERSION
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bc bison build-essential ca-certificates curl flex libelf-dev \
        libssl-dev python3 xz-utils zstd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# kata's guest kernel .config plus the upstream default QEMU runtime config
RUN curl -fsSL "https://github.com/kata-containers/kata-containers/releases/download/${KATA_VERSION}/kata-static-${KATA_VERSION}-amd64.tar.zst" \
        | zstd -d \
        | tar -x ./opt/kata/share/kata-containers ./opt/kata/share/defaults/kata-containers

# The kernel version is whatever kata shipped a config for, so it can never
# drift from what the guest image and agent expect.
RUN kver="$(ls -1 opt/kata/share/kata-containers/config-* | head -1 | xargs -n1 basename | sed 's/^config-//; s/-[0-9]\+$//')" \
    && echo "${kver}" > /kver \
    && curl -fsSL "https://cdn.kernel.org/pub/linux/kernel/v${kver%%.*}.x/linux-${kver}.tar.xz" | tar xJ

RUN kver="$(cat /kver)" \
    && cd "linux-${kver}" \
    && cp ../opt/kata/share/kata-containers/config-* .config \
    && ./scripts/config --enable CONFIG_VIRTUALIZATION \
                        --enable CONFIG_KVM \
                        --enable CONFIG_KVM_INTEL \
                        --enable CONFIG_KVM_AMD \
    && make olddefconfig \
    && grep -q '^CONFIG_KVM=y' .config \
    && grep -q '^CONFIG_KVM_INTEL=y' .config \
    && make -j"$(nproc)" vmlinux \
    && cp vmlinux /vmlinux-nested

# The two rewrites the kata-containers extension applies to the upstream default
# (/opt/kata -> /usr/local, blanked firmware_volume), plus our kernel path. The
# result is byte-identical to the extension's configuration-qemu.toml except for
# that one line, which is asserted here rather than trusted.
RUN sed -e 's|/opt/kata|/usr/local|g' \
        -e 's|^firmware_volume = .*|firmware_volume = ""|' \
        -e 's|^kernel = .*|kernel = "/var/lib/kata-nested/vmlinux-nested"|' \
        opt/kata/share/defaults/kata-containers/configuration-qemu.toml \
        > /configuration-qemu.toml \
    && grep -q '^kernel = "/var/lib/kata-nested/vmlinux-nested"$' /configuration-qemu.toml \
    && grep -q '^path = "/usr/local/bin/qemu-system-x86_64"$' /configuration-qemu.toml \
    && ! grep -q '/opt/kata' /configuration-qemu.toml

FROM docker.io/library/busybox:stable-musl
COPY --from=build /vmlinux-nested /artifacts/vmlinux-nested
COPY --from=build /configuration-qemu.toml /artifacts/configuration-qemu.toml
