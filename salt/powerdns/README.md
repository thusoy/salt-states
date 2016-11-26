powerdns
========

Installs powerdns master with postgres backend. Default to installing pdnd-server from default repos, but can be configured for the official powerdns repos.

Pillar example:

```yaml
powerdns:
    repo: auth-40
    db_password: |
        -----BEGIN PGP MESSAGE-----
        <..>
        -----END PGP MESSAGE-----
```
