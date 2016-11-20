poff
====

Sets up a front-end to PowerDNS.

Pillar example:

```yaml
poff:
    db_password: something random
    secret_key: something other random thingie
```

The database user will be created with that password, the assumption is that poff runs on the same host as the database. If that assumption doesn't hold, fork and fix.

Note that there's no authentication built-in, it's assumed you authenticate on a higher level (like nginx PAM auth or similar).
