# Boto HMAC

Deploys `/root/.boto` with credentials from pillar.

```yaml

boto:
    access_key_id: keyid
    secret_access_key: secret
```

Optionally the values can also be loaded indirectly from another pillar:

```yaml
boto:
    acccess_key_id_pillar: other_pillar:access_key
    secret_access_key_pillar: other_pillar:secret_key

other_pillar:
    access_key: keyid
    secret_key: secret
```
