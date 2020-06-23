# rabbitmq

Install RabbitMQ 3.8 with Erland 23. There's a substate `rabbitmq.management` that will
enable the management plugin and enable the users `admin` and `monitoring` with
the respective tags. The state is designed to be run the management plugin behind a
reverse proxy like nginx, and thus doesn't expose any services externally, but this can be
overridden with `rabbitmq:management_expose_plaintext` for local environments and similar.

Note that this state only works with salt 3001 and newer due to an incompatibility with older
versions of salt and rabbitmq >= 3.8.

Configuration:

```yaml
rabbitmq:
    admin_password: password
    monitoring_password: password
    management_tls_cert: |
        -----BEGIN CERTIFICATE-----
        MIIDejCCA..
        -----END CERTIFICATE-----
    management_tls_key: |
        -----BEGIN RSA PRIVATE KEY-----
        MIIEpAIBAAKCA..
        -----END RSA PRIVATE KEY-----
```
