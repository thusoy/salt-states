# rabbitmq

Install RabbitMQ 3.8 with Erland 23. There's a substate `rabbitmq.management` that will
enable the management plugin over https and enable the users `admin` and `monitoring` with
the respective tags.

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
