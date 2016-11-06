certbot
=======

Installs certbot and fetches certs for the requested domains, using a
standalone server for authentication. Nginx will be stopped and started during
certificate renewal.

Pillar example:

```yaml
certbot:
    administrative_contact: <somename>@<somedomain>
    sites:
        - example.com
        - othersite.com
```

The different sites will each get their own certificate in
`/etc/letsencrypt/live/<site>/fullchain.pem` and a key in
`/etc/letsencrypt/live/<site>/privkey.pem`.


Compatibility
-------------

This state is compatible with at least Debian Jessie and later and Ubuntu Xenial and later.
