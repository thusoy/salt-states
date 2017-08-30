rsyslog
=======

Installs and configures rsyslog.

Pillar example:

```yaml
rsyslog:
    outputs:
        - '*.* @logsN.papertrailapp.com:PORT'
```
