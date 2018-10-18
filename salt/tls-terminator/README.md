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

`cert` and `key` is only needed if you want to override the nginx default cert set through
`nginx:default_cert`.

If you want to have different backends for different URLs, you can set the `backends` parameter
instead:

```yaml
tls-terminator:
    otherexample.com:
        backends:
            /: https://example-app.herokuapp.com
            /api: https://api-app.herokuapp.com
```

A HTTPS backend is validated against the system trust root if no explicit trust root is given. To
set a trust root:

```yaml
tls-terminator:
    example.com:
        backends:
            /:
                upstream: https://example-app.herokuapp.com
                upstream_trust_root: |
                    <upstream-cert>
```

As you might have guessed, `backend: <url>` is just a convenient alias for
`backends: {"/": {"upstream": <url>}}`.

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

You can also add a redirect to another site:

```yaml
tls-terminator:
    www.example.com:
        redirect: 301 https://example.com/$request_uri

    example.com:
        backend: https://example-app.herokuapp.com
```


To set up rate-limiting:

```yaml
tls-terminator:
    example.com:
        rate_limit:
            zones:
                default:
                    key: $cookie_session
                    size: 10m
                    rate: 1r/s
                sensitive:
                    rate: 6r/m
                    # key defaults to $binary_remote_addr when unset
                    # size defaults to 1m when unset
            backends:
                /:
                    zone: default
                    burst: 3
                /login:
                    zone: sensitive
                    burst: 4
        backend: http://127.0.0.1:5000
```

Each backend defaults to setting the `nodelay` flag, this can be turned off per backend by setting
`nodelay: False`.


When forwarding requests there are a couple common errors that can originate at the tls-terminator,
like 502 (Bad Gateway), 504 (Gateway Timeout) and 429 (Too Many Requests, only when setting rate
limits). The state includes default error pages for these conditions, but you can also override
these if you want to put special styling on them. They have to be a single page of html, and can be
set both globally for all sites in the state or on a per-site basis:

```yaml
tls-terminator:
    error_pages:
        429: |
            <!doctype html>
            <title>My custom rate limited error page</title>
            <p>Your requests to {{ site }} have been rate limited</p>
    example.com:
        backend: http://127.0.0.1:5000
        error_pages:
            429: |
                <!doctype html>
                <title>Too many requests to example.com</title>
```

The error page can be a jinja template, and will receive the name of the site in a variable `site`
that can be used to customize the page. The page defaults to being served as html, the content type
can be overridden like this:

```yaml
tls-terminator:
    api.example.com:
        error_pages:
            504:
                content_type: application/json
                content: |
                    {
                        "error": {
                            "status": 504,
                            "message": "Gateway timeout",
                        }
                    }
```

The custom error pages are only used for errors originating from the tls-terminator, if the upstream
returns any of the errors itself the response is sent unmodified to the client.
