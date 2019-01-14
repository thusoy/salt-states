# ACME DNS01

This is a state to help get ACME certificates into pillar. The certificates are fetched and refreshed by a cron job running on the saltmaster, and an extension module reads the results into pillar. The extension module is expected to be added to the saltmaster config manually, but it'll be added to the saltmaster by the state.

Should this attempt to restart the saltmaster? Hard to do from a minion position. Split config from salt master config to not need to restart the saltmaster.

The domains to fetch certificates for are itself specified in pillar, and will after the next run of the cronjob be available for other states to use.

Add the following to your saltmaster config and restart:

```yaml
extension_modules: /usr/local/lib/acme-dns/extensions
ext_pillar:
    - acme_dns: []
```


## Configuration


```yaml
acme-dns:
    contact: acme@example.com
    zones:
        -
            # Where to send the DNS update
            update-server: ns.example.com
            key-name: acme
            key-secret: secretsecret
            key-algorithm: hmac-sha256
            # (optional) The zone used in the DNS update
            zone: example.com
            certificates:
                # The hostname to fetch certificates for
                - hostname: example.com
                # Glob of minions which should have access to the
                # cert and key for this hostname.
                available-to: *.web.example.com

    # (optional) Set this if you already have a directory where you're
    # collecting extension modules.
    extensions-directory: /usr/local/lib/acme-dns/extensions
```

The state assumes the saltmaster is running as an unprivileged user. If this is not the case, or the user is not called 'saltmaster', specify this:

```yaml
acme-dns:
    saltmaster_user: root
```
