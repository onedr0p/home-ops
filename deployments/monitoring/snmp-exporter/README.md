# snmp-exporter

## Generate config

This will create a `snmp.yml` file which will be needed for snmp-exporter. The MIB below is specific for Cyberpowers PDUs and UPSs

```bash
sudo apt-get install unzip build-essential libsnmp-dev golang
go get github.com/prometheus/snmp_exporter/generator
cd ${GOPATH-$HOME/go}/src/github.com/prometheus/snmp_exporter/generator
go build
make mibs
wget https://dl4jz3rbrsfum.cloudfront.net/software/MIB_v23.zip
unzip MIB_v23.zip
mv MIB002-0001-10.mib mibs/
export MIBDIRS=mibs
./generator generate
```
