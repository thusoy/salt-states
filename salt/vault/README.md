# Vault

Installs vault.

References:
[Vault Deployment Guide](https://learn.hashicorp.com/vault/operations/ops-deployment-guide)
[Production Hardening](https://learn.hashicorp.com/vault/day-one/production-hardening)
[Upgrading](https://www.vaultproject.io/docs/upgrading/)


## Configuration

The config given in the pillar `vault:server_config` will be merged with the defaults
defined in `map.jinja` and written to the server config files as json. This means that
instead of writing
```
variable "ami" {
    description = "the AMI to use"
}
```

You should write

```yaml
vault:
    server_config:
        variable:
            ami:
                description: 'the AMI to use'
```


### Authentication

If your vault setup requires authentication to external services like GCS for
storage or an external KMS, you can add config for that in pillar, and it'll
be deployed as files only accessible to the vault user:

```yaml
vault:
    auth:
        <auth-name>:
            filename: <filename in /etc/vault>
            environment_variable_name: <name of envvar>
            secret: |
                <the contents of the file>
```

Example:

```yaml
vault:
    auth:
        gc:
            filename: gc.json
            environment_variable_name: GOOGLE_APPLICATION_CREDENTIALS
            secret: |
                {
                    "type": "service_account",
                    "project_id": "vault-XXX",
                    ..
                }
```


## Operations

Vault is installed from the Hashicorp apt repo. To apply updates, run
`sudo salt <minion> pkg.install vault`, followed by `sudo salt <minion> service.restart vault`.
Remember to only run the latter for one minion in the cluster at a time to avoid making
the entire cluster unavailable simultaneously. If you don't use automatic unsealing make
sure secondary nodes are restarted first and unsealed before restarting (and unsealing)
the current primary.
