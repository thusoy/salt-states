# mysql

This state installs mysql intended for development environments. Thus it makes no effort
to configure TLS or similar. The only thing that can be configured at the moment is the
address to bind to and the major version of mysql to install:

```yaml
mysql:
    server:
        version: 8.0 # default: 5.7
        bind: 127.0.0.1 # default: 0.0.0.0
```
