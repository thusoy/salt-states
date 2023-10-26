# Boto

Deploys `/root/.boto` with config from pillar. Keys suffixed with `_pillar` will be loaded from another pillar. High level keys are sections.

```yaml
boto:
    Credentials:
        access_key_id: keyid
        secret_access_key: secret
```
