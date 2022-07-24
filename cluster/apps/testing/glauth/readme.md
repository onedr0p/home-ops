# glauth

## Config

```toml
debug = true
[ldap]
    enabled = true
    listen = "0.0.0.0:3893"
[ldaps]
    enabled = false
[api]
    enabled = true
    tls = false
    listen = "0.0.0.0:5555"
[backend]
    datastore = "config"
    baseDN = "dc=home,dc=arpa"
[[groups]]
    name = "svc"
    gidnumber = 5500
[[users]]
    name = "admin"
    uidnumber = 5000
    primarygroup = 5500
    passsha256 = "140bedbf9c3f6d56a9846d2ba7088798683f4da0c248231336e6a05679e4fdfe"
    [[users.capabilities]]
        action = "search"
        object = "*"
[[groups]]
    name = "people"
    gidnumber = 6500
[[users]]
    name = "devin"
    uidnumber = 6000
    primarygroup = 6500
    passsha256 = "140bedbf9c3f6d56a9846d2ba7088798683f4da0c248231336e6a05679e4fdfe"
    [[users.customattributes]]
        objectClass = ["person"]
```
