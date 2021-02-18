# Ubuntu autoinstall for my Intel NUCs

Project to build custom Ubuntu 20.04 ISOs for my Intel NUCs. Using [autoinstall](https://ubuntu.com/server/docs/install/autoinstall) the Ubuntu install will be automated and headless!

## Background

Bare-metal has it's advantages and disadvantages. I own 8 Intel NUCs and needed a quick way to freshly install an OS, without mucking with PXE. Before I was stuck hooking up a keyboard, monitor and USB drive and manually walking thru the install steps in the UI for each NUC! Thankfully now I only need a USB drive and the Intel BIOS setting **Boot USB devices first** enabled.

## Usage

Docker will build two ISOs each with slightly different config for my cluster. The autoinstall files are in the [autoinstall](./autoinstall) directory.

_If you know your NIC interfaces and block devices you want to install Ubuntu on then using my autoinstall files might just work for you too._

```fish
# Make sure you are shelled into this directory and the proceed with the following...

# Build the docker image to generate the ISOs
docker build -t autoinstall-ubuntu:latest .
# Generate the ISOs
docker run --rm -v $(pwd)/build:/build autoinstall-ubuntu
```

Flash these ISOs onto a USB thumbdrive, insert them into your NUC and reboot. In roughly 4 minutes the NUC will poweroff, remove the USB thumbdrive and power it back on. You should be able to pick up the IP assigned via DHCP in your router settings. You may also want to make it staticly assigned in your router.

![](https://i.kym-cdn.com/photos/images/original/000/634/985/2d7.gif)

In order to first get the autoinstall files you may want to install Ubuntu Server 20.04 by hand. This way you can grab the autoinstall file it automatically generates.
The file is located under **`/var/log/installer/autoinstall-user-data`**. It is worth saying however, this file may not work right off the bat and may take some tinkering with in-order to make it work.

## References

_Here are some use links that I read thru, you may find them useful too._

- https://gist.github.com/s3rj1k/55b10cd20f31542046018fcce32f103e
- https://utcc.utoronto.ca/~cks/space/blog/linux/Ubuntu2004AutoinstFormat
- https://discourse.ubuntu.com/t/please-test-autoinstalls-for-20-04/15250
- https://nickcharlton.net/posts/automating-ubuntu-2004-installs-with-packer.html
