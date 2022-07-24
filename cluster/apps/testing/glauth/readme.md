# glauth

## Config

```toml
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
baseDN = "dc=google,dc=com"
[[users]]
name = "svcacct"
mail = "svcacct@svcaccts"
uidnumber = 5003
primarygroup = 5502
passsha256 = "140bedbf9c3f6d56a9846d2ba7088798683f4da0c248231336e6a05679e4fdfe"
[[users.capabilities]]
action = "search"
object = "*"
[[users]]
name = "devin"
mail = "devin@derp"
uidnumber = 5001
primarygroup = 5501
passsha256 = "140bedbf9c3f6d56a9846d2ba7088798683f4da0c248231336e6a05679e4fdfe"
[[users]]
name = "louie"
mail = "louie@derp"
uidnumber = 5002
primarygroup = 5501
passsha256 = "140bedbf9c3f6d56a9846d2ba7088798683f4da0c248231336e6a05679e4fdfe"
[[groups]]
name = "svcaccts"
gidnumber = 5502
[[groups]]
name = "users"
gidnumber = 5501
```
