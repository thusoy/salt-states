nginx
=====

Installs nginx. Through pillar you can customize HTTP keepalive time and custom log formats and log
files. Arbitrary additions to the http block is also possible.

Pillar example:

```yaml
nginx:
    keepalive_timeout: 600 # 10 minutes
    log_formats:
        main: '$remote_addr [$time_local] $http_host $request_id $request'
        cache: '$remote_addr [$time_local] $upstream_cache_status $http_host $request'
    log_files:
        cache.log: cache
```

This will set up two log formats, `main` and `cache` (main is always present if you don't specify
it), and two differnet log files in `/var/log/nginx/`, `access.log` (uses the `main` format by
default), and `cache.log`, using the `cache` format.

To add to the http block, say adding a `$do_error_log` variable that will hold whether the response
was client error (HTTP status 4xx):

```yaml
nginx:
    extra_http:
        - map: |
            $status $client_error {
                ~^4 1;
                default 0;
            }
    log_files:
        client_error.log: main if=$client_error;
```

To write logs to syslog:

```yaml
nginx:
    log_outputs:
        - logger: access_log
          spec: syslog:server=unix:/dev/log
          format: main
```

To enable only whitelisted IPs access to the instance:

```yaml
nginx:
    allow_sources_v4:
        - 1.2.3.4
        - 5.6.7.8
    allow_sources_v6:
        - 2a03::c001
```

By default the instance will be publicly accessible.
