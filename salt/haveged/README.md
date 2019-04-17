haveged
=======

Installs haveged. The default low entropy watermark is 1024, this can be configured through pillar:

```yaml
haveged:
    low_entropy_watermark: 512
```
