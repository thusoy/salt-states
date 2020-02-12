# Vault

Installs vault.

To get the version spec for the latest version to put into your own pillar or
update the default in this state, run `./get-latest-version.sh`, which securely
fetches the latest version and valiates the hash against the release key.

References:
[Vault Deployment Guide](https://learn.hashicorp.com/vault/operations/ops-deployment-guide)
[Production Hardening](https://learn.hashicorp.com/vault/day-one/production-hardening)
[Upgrading](https://www.vaultproject.io/docs/upgrading/)


## Configuration

The config given in the pillar `vault:config` will be merged with the defaults defined in `map.jinja` and written to the
config files as json. This means that instead of writing
```
variable "ami" {
    description = "the AMI to use"
}
```

You should write

```yaml
vault:
    config:
        variable:
            ami:
                description: 'the AMI to use'
```


## Operations

The version of vault to use is coded into the state and/or pillar. The state
will install newer versions and restart the service if this changes. Make sure
this rolls out to secondary nodes first (and make sure they are unsealed),
before applying to the primary.
