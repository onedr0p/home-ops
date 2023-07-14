# Ansible

## Debian

There is a decent guide [here](https://www.linuxtechi.com/how-to-install-debian-12-step-by-step/) on how to get Debian installed. There are some deviations I made from this guide.

- Choose `Guided - use entire disk`
- Choose `All files in one partition`
- Delete Swap partition
- Uncheck all Debian desktop environment options

### Manual steps (Pre-Ansible)

1. Enable SSH for root user

    ```sh
    sed -i 's/#\?\(PermitRootLogin\s*\).*$/\1yes/' /etc/ssh/sshd_config
    systemctl restart sshd
    ```

2. Add SSH keys (or use `ssh-copy-id` on the client that is connecting)

    ```sh
    mkdir -m 700 ~/.ssh
    curl https://github.com/onedr0p.keys > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    ```

3. Remove CD/DVD as apt source

    ```sh
    sed -i '1d' /etc/apt/sources.list
    apt update
    ```
