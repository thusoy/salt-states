do-agent
========

Installs the Digital Ocean monitoring agent.

Digial Ocean sets the "manufacturer" info on the droplet, which is available through grains. Thus, to apply this to only your Digital Ocean minions in your topfile:

```yaml
base:
    manufacturer:DigitalOcean:
        - match: grain
        - do-agent
```
