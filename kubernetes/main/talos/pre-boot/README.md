# Talos Pre-boot

Enable Thunderbolt Pre-boot

<https://www.talos.dev/latest/reference/kernel/#talosconfiginline>

## Image Factory

1. Generate compressed encoded string

    ```sh
    cat kubernetes/main/talos/pre-boot/config.yaml | zstd --compress --ultra -22 | base64 -w 0
    ```

2. Add to Talos Image Factory Kernel args

    ```text
    talos.config.inline=KLUv/QSIPQQAAkgbGVDVA4BRNSf9OC1i0JDCkvyYzEPinsxkUjBO/4V8+Gpeiiv7Nz/l7h58wkY/mzKuek+NkZJw4GmLo/z07qpfjMkhm6cpnMaBR+l8MSoLIg3CA/fr7c7u2NPt7oa/U5Vm5eCslp0Q8+Hi6cqPBQgAPRaIGJcb5VAxljrp20QB6DImg/sEh9H2Og==
    ```
