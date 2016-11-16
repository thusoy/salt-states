nginx
=====

Installs nginx. Through pillar you can customize HTTP keepalive time and custom log formats and log files.

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
