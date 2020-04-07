# salt-minion

This state configures the salt-minion to allow communication to the saltmaster
through the firewall and sets up `state.apply` to be run on a regular schedule.

By default `state.apply` will run at a random time every 8 hours, but this can
be customized through pillar:

```yaml
salt_minion:
    apply_schedule:
        hour: '*' # We have to override the default if we want to run every hour
        minute: 'random'
```
