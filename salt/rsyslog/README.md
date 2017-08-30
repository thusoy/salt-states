rsyslog
=======

Installs and configures rsyslog.

Pillar example:

```yaml
rsyslog:
    outputs:
        - '*.* @logsN.papertrailapp.com:PORT'
```

There's also a helper module if you want to use with Papertrail:

```yaml
rsyslog:
    papertrail: '*.* @@logsN.papertrailapp.com:PORT'
```

The latter automatically configures delivery to the papertrail destination over
TLS with retries on failed connections.
