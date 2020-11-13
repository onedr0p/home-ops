# snmp-exporter

Retrieve metrics from devices that only support monitoring via SNMP. For now I am usng snmp-exporter for getting metrics from my Cyberpower PDUs (model PDU41001) and my APC UPS (Smart-UPS 1500)

## Clone and build the snmp-exporter generator

```bash
sudo apt-get install unzip build-essential libsnmp-dev golang
go get github.com/prometheus/snmp_exporter/generator
cd ${GOPATH-$HOME/go}/src/github.com/prometheus/snmp_exporter/generator
go build
make mibs
```

## Update generator.yml

Kubernetes configmaps have a max size. I needed to srip out all the other modules.

```yaml
modules:
  apcups:
    version: 1
    walk:
      - sysUpTime
      - interfaces
      - 1.3.6.1.4.1.318.1.1.1.2       # upsBattery
      - 1.3.6.1.4.1.318.1.1.1.3       # upsInput
      - 1.3.6.1.4.1.318.1.1.1.4       # upsOutput
      - 1.3.6.1.4.1.318.1.1.1.7.2     # upsAdvTest
      - 1.3.6.1.4.1.318.1.1.1.8.1     # upsCommStatus
      - 1.3.6.1.4.1.318.1.1.1.12      # upsOutletGroups
      - 1.3.6.1.4.1.318.1.1.10.2.3.2  # iemStatusProbesTable
      - 1.3.6.1.4.1.318.1.1.26.8.3    # rPDU2BankStatusTable
    lookups:
      - source_indexes: [upsOutletGroupStatusIndex]
        lookup: upsOutletGroupStatusName
        drop_source_indexes: true
      - source_indexes: [iemStatusProbeIndex]
        lookup: iemStatusProbeName
        drop_source_indexes: true
    overrides:
      ifType:
        type: EnumAsInfo
      rPDU2BankStatusLoadState:
        type: EnumAsStateSet
      upsAdvBatteryCondition:
        type: EnumAsStateSet
      upsAdvBatteryChargingCurrentRestricted:
        type: EnumAsStateSet
      upsAdvBatteryChargerStatus:
        type: EnumAsStateSet
  cyberpower:
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

This will create a `snmp.yml` file which will be needed for the configmap for snmp-exporter

```bash
export MIBDIRS=mibs
./generator generate
```
