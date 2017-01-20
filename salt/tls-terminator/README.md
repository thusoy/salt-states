tls-terminator
==============

Configures nginx as TLS terminator for a http(s) backend.

Sample pillar config:

```yaml
tls-terminator:
    example.com:
        backend: https://example-app.herokuapp.com
        cert: |
            ---BEGIN CERTIFICATE----
            <snip>
            ---END CERTIFICATE------
        key: |
            ---BEGIN PRIVATE KEY----
            <snip>
            ---END PRIVATE KEY------
```

`cert` and `key` is only needed if you want to override the nginx default cert set through `nginx:default_cert`.

If you want to have different backends for different URLs, you can set the `backends` parameter instead:

```yaml
tls-terminator:
    otherexample.com:
        backends:
            /: https://example-app.herokuapp.com
            /api: https://api-app.herokuapp.com
```

A HTTPS backend is validated against the system trust root if no explicit trust root is given. To set a trust root:

```yaml
tls-terminator:
    example.com:
        backends:
            /:
                upstream: https://example-app.herokuapp.com
                upstream_trust_root: |
                    <upstream-cert>
```

As you might have guessed, `backend: <url>` is just a convenient alias for `backends: {"/": {"upstream": <url>}}`.

You can add extra location blocks if needed:

```yaml
tls-terminator:
    example.com:
        backend: https://example-app.herokuapp.com
        extra_locations:
            /.well-known/assetlinks.json: |
                return 200 '[{ "namespace": "android_app",
                   "package_name": "org.digitalassetlinks.example",
                   "sha256_cert_fingerprints":
                     ["14:6D:E9:83:C5:73:06:50:D8:EE:B9:95:2F:34:FC:64:16:"
                      "A0:83:42:E6:1D:BE:A8:8A:04:96:B2:3F:CF:44:E5"]}]';
```
