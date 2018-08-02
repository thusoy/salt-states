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

To use extra extensions modules:

```yaml
nginx:
    package: nginx-full
    modules:
        - /usr/lib/nginx/modules/ngx_http_geoip_module.so
        - /usr/lib/nginx/modukes/ngx_http_upstream_fair_module.so
```

Note that normally nginx will be installed from the official nginx apt repo, not the standard debian
repo. The `nginx-full` package however is provided by debian and will cause the standard debian
version to be installed, which lags a couple versions behind latest, but includes a lot of extension
packages packaged by debian in stretch and newer.


## Regular reloads

Since nginx doesn't reload DNS records after boot, you might want to reload regularly to ensure the
records stay fresh. If you include the state `nginx.regular_reload` a cronjob will be added that
reloads the nginx instance hourly.

Note that reloads are graceful, no requests are dropped during a reload.

To customize the reload interval:

```yaml
nginx:
    regular_reload:
        minute: '*/10'
```

This will reload every 10 minutes. If you want less frequent reloads:

```yaml
nginx:
    regular_reload:
        minute: 15
        hour: '*/5'
```

This will reload 15 minutes past every fifth hour. The `regular_reload` state accepts the same
parameters as the salt `cron` state (`minute`, `hour`, `daymonth`, `dayweek`, `month`).

**NB:** If you specify `random` it'll pick a random value, which can be handy to ensure not all
servers reload at the same time if you have multiple servers. But do note that an earlier value
will not be reset if using `random`, so if you had `minute: '*/5'` in your config to reload every
fifth minute, but later changed this to `minute: random` the reload interval will not change. This
is due to how the salt `cron` state works.
