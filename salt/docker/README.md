# docker.io

Installs the docker that is shipped in the standard Debian repos, and configures it to enable overriding the listener address.

To make the docker daemon externally accessible:

```yaml
docker:
    hosts:
        - tcp://0.0.0.0:2376
```
