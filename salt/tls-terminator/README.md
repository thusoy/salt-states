tls-terminator
==============

Configures nginx as TLS terminator for a http(s) backend.

Sample pillar config:

```
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

```
tls-terminator:
    otherexample.com:
        backends:
            /: https://example-app.herokuapp.com
            /api: https://api-app.herokuapp.com
```

A HTTPS backend is validated against the system trust root if no explicit trust root is given. To set a trust root:

```
tls-terminator:
    example.com:
        backends:
            /:
                upstream: https://example-app.herokuapp.com
                upstream_trust_root: |
                    <upstream-cert>
```

As you might have guessed, `backend: <url>` is just a convenient alias for `backends: {"/": {"upstream": <url>}}`.
