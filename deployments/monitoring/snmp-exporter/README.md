# snmp-exporter

## Generate config

This will create a `snmp.yml` file which will be needed for snmp-exporter. The MIB below is specific for Cyberpowers PDUs and UPSs

## Clone and build the snmp-exporter generator

```bash
sudo apt-get install unzip build-essential libsnmp-dev golang
go get github.com/prometheus/snmp_exporter/generator
cd ${GOPATH-$HOME/go}/src/github.com/prometheus/snmp_exporter/generator
go build
make mibs
```

## Update generator.yml

```yaml
modules:
  cyber_power:
    version: 1
    walk:
      - ePDUIdentName
      - ePDUIdentHardwareRev
      - ePDUStatusInputVoltage      ## input voltage (0.1 volts)
      - ePDUStatusInputFrequency    ## input frequency (0.1 Hertz)
      - ePDULoadStatusLoad          ## load (tenths of Amps)
      - ePDULoadStatusVoltage       ## voltage (0.1 volts)
      - ePDULoadStatusActivePower   ## active power (watts)
      - ePDULoadStatusApparentPower ## apparent power (VA)
      - ePDULoadStatusPowerFactor   ## power factor of the output (hundredths)
      - ePDULoadStatusEnergy        ## apparent power measured (0.1 kw/h).
      - ePDUOutletControlOutletName ## The name of the outlet.
      - ePDUOutletStatusLoad        ## Outlet load  (tenths of Amps)
      - ePDUOutletStatusActivePower ## Outlet load  (watts)
      - envirTemperature            ## temp expressed  (1/10 ºF)
      - envirTemperatureCelsius     ## temp expressed  (1/10 ºF)
      - envirHumidity               ## relative humidity (%)
```

## Get the Cyberpower MIB

```bash
wget https://dl4jz3rbrsfum.cloudfront.net/software/CyberPower_MIB_v2.9.MIB.zip
unzip CyberPower_MIB_v2.9.MIB.zip
mv CyberPower_MIB_v2.9.MIB mibs/
```

## Generate the snmp.yml

```bash
export MIBDIRS=mibs
./generator generate
```