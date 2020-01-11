# ESXi

> *Note*: this document is a work in progress

## Configure

- Disable IPv6 ESXi
- Set swap ESXi
- Set and enable NTP on ESXi (0.us.pool.ntp.org,1.us.pool.ntp.org,2.us.pool.ntp.org,3.us.pool.ntp.org)
- Set and enable SSH on ESXi
- Set NVMe pass-through for Intel NUC storage nodes
- Set iGPU pass-through for Intel NUC worker nodes

## Update ESXi

```bash
esxcli network firewall ruleset set -e true -r httpClient

cd /tmp

wget http://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/tools-light/VMware_locker_tools-light_11.0.1.14773994-15160134.vib

esxcli software vib install -f -v /tmp/VMware_locker_tools-light_11.0.1.14773994-15160134.vib

rm -rf /tmp/VMware_locker_tools-light_11.0.1.14773994-15160134.vib

esxcli software profile update -p ESXi-6.7.0-20191204001-standard -d https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/vmw-depot-index.xml

esxcli network firewall ruleset set -e false -r httpClient
```

## Update ESXi if storage errors

```bash
# https://esxi-patches.v-front.de/ESXi-6.7.0.html
cd /vmfs/volumes/local-datastore-b/scratch

wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/elx-esx-libelxima.so/VMware_bootbank_elx-esx-libelxima.so_11.4.1184.2-3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/esx-base/VMware_bootbank_esx-base_6.7.0-3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/esx-update/VMware_bootbank_esx-update_6.7.0-3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/native-misc-drivers/VMware_bootbank_native-misc-drivers_6.7.0-3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/net-vmxnet3/VMW_bootbank_net-vmxnet3_1.1.3.0-3vmw.670.3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/tools-light/VMware_locker_tools-light_11.0.1.14773994-15160134.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/vmkusb/VMW_bootbank_vmkusb_0.1-1vmw.670.3.89.15160138.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/vsan/VMware_bootbank_vsan_6.7.0-3.89.14840357.vib && \
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/vsanhealth/VMware_bootbank_vsanhealth_6.7.0-3.89.14840358.vib

esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_elx-esx-libelxima.so_11.4.1184.2-3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_esx-base_6.7.0-3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_esx-update_6.7.0-3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_native-misc-drivers_6.7.0-3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMW_bootbank_net-vmxnet3_1.1.3.0-3vmw.670.3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_locker_tools-light_11.0.1.14773994-15160134.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMW_bootbank_vmkusb_0.1-1vmw.670.3.89.15160138.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_vsanhealth_6.7.0-3.89.14840358.vib && \
esxcli software vib install -f -v /vmfs/volumes/local-datastore-b/scratch/VMware_bootbank_vsan_6.7.0-3.89.14840357.vib
```

## Downgrade or upgrade NVMe driver

```bash
wget https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/nvme/VMW_bootbank_nvme_1.2.2.28-1vmw.670.3.73.14320388.vib

esxcli software vib install -f -v /tmp/VMW_bootbank_nvme_1.2.2.28-1vmw.670.3.73.14320388.vib

https://hostupdate.vmware.com/software/VUM/PRODUCTION/main/esx/vmw/vib20/nvme/VMW_bootbank_nvme_1.2.1.34-1vmw.670.0.0.8169922.vib
```

## Format drive for datastore if it doesn't show up

```bash
esxcli storage core device list
partedUtil mklabel /vmfs/devices/disks/t10.ATA_____Samsung_SSD_840_EVO_750GB_______________S1DMNEAD915457R_____ gpt
```

## Make scratch directory

```bash
mkdir /vmfs/volumes/local-datastore-f/scratch
```
