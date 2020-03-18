# Unbound

Installs and configures unbound. You need to edit `/etc/resolv.conf` outside of
this state to actually start using it.

Configure through pillar:

```yaml
unbound:
    config:
        server:
            log-queries: 'yes'
            log-replies: 'yes'
            log-tag-queryreply: 'yes'
            serve-expired-ttl-reset: 'yes'
```
