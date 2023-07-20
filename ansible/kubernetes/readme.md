# Ansible

## Debian

There is a decent guide [here](https://www.linuxtechi.com/how-to-install-debian-12-step-by-step/) on how to get Debian installed.

1. Deviations from that guide

    ```txt
    - Choose "Guided - use entire disk"
    - Choose "All files in one partition"
    - Delete Swap partition
    - Uncheck all Debian desktop environment options
    ```

2. [Post install] Remove CD/DVD as apt source

    ```sh
    su -
    sed -i '/deb cdrom/d' /etc/apt/sources.list
    apt update
    exit
    ```

3. [Post install] Enable sudo for your non-root user

    ```sh
    su -
    apt install sudo
    usermod -aG sudo ${username}
    echo "${username} ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/${username}
    exit
    newgrp sudo
    sudo apt update
    ```

4. [Post install] Add SSH keys (or use `ssh-copy-id` on the client that is connecting)

    ```sh
    mkdir -m 700 ~/.ssh
    sudo apt install curl
    curl https://github.com/${github_username}.keys > ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    ```
