# logrotate

Enables installing and setting the logrotate schedule. By default on Debian
logrotate runs daily, thus setting `hourly` in an individual logrotate file
doesn't have any effect. This state enables setting logrotate to run hourly,
making other files with `hourly` specs also work.

```yaml
logrotate:
    schedule: hourly
```
