# Redis

Installs redis.

To set a password, add the following in pillar:

```yaml
redis:
    password: <some-password>
```

Alternatively, if the password exists in another pillar:

```yaml
redis:
    password_pillar: other:value

other:
    value: redispass
```

To set a memory policy:

```yaml
redis:
    maxmemory: 70%
    maxmemory-policy: volatile-lru
```
