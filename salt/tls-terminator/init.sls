#!py

import hashlib
import re
import unicodedata
import urlparse


def run():
    """Create the states for the TLS-terminator backends."""

    sites = __pillar__.get('tls-terminator', {})

    ret = {
        "include": [
            "nginx"
        ]
    }

    outgoing_firewall_ports = set()

    for site, values in sites.items():
        backend = values.get('backend')
        backends = values.get('backends', {})
        if not (backend or backends):
            raise ValueError('TLS-terminator site "%s" is missing one of the required properties backend/backends' %
                site)

        if backend and backends:
            raise ValueError('TLS-terminator site "%s" specifies both backend and backends, must only specify one' %
                site)

        if backend:
            backends['/'] = {
                'upstream': backend,
            }

        for url, backend_config in backends.items():
            if not isinstance(backend_config, dict):
                backends[url] = {
                    'upstream': backend_config,
                }

        parsed_backends = {}
        for url, backend_config in backends.items():
            backend = backend_config['upstream']
            normalized_backend = '//' + backend if not '://' in backend else backend
            parsed_backend = urlparse.urlparse(normalized_backend)
            protocol = parsed_backend.scheme or 'http'
            port = parsed_backend.port or ('443' if protocol == 'https' else 80)
            upstream_identifier = get_upstream_identifier_for_backend(site, parsed_backend.hostname,
                url)

            if protocol == 'https':
                # If backend is https it's going out over the network, thus allow it through
                # the firewall
                outgoing_firewall_ports.add(port)

            upstream_trust_root = '/etc/nginx/ssl/all-certs.pem'
            if 'upstream_trust_root' in backend_config:
                upstream_trust_root = '/etc/nginx/ssl/%s-upstream-root.pem' % upstream_identifier
                ret['tls-terminator-%s-upstream-trust-root' % upstream_identifier] = {
                    'file.managed': [
                        {'name': upstream_trust_root},
                        {'contents': backend_config.get('upstream_trust_root')},
                        {'require_in': [
                            {'file': 'tls-terminator-%s-nginx-site' % site},
                        ]},
                    ]
                }

            upstream_hostname = parsed_backend.hostname
            if 'upstream_hostname' in backend_config:
                upstream_hostname = backend_config.get('upstream_hostname')
                if upstream_hostname == 'site':
                    upstream_hostname = site

            parsed_backends[url] = {
                'hostname': parsed_backend.hostname,
                'upstream_hostname': upstream_hostname,
                'protocol': protocol,
                'port': port,
                'upstream_identifier': upstream_identifier,
                'upstream_trust_root': upstream_trust_root,
            }

        site_504_page = [
            {'name': '/usr/local/nginx/html/504-' + site + '.html'},
            {'source': 'salt://tls-terminator/nginx/504.html'},
            {'makedirs': True},
            {'template': 'jinja'},
            {'context': {
                'site': site,
            }}
        ]
        ret['tls-terminator-timeout-page-' + site] = {'file.managed': site_504_page}

        use_acme_certs = values.get('acme')
        if use_acme_certs:
            # The actual certs will be managed by the certbot state (or equivalent)
            cert = '/etc/letsencrypt/live/%s/fullchain.pem' % site
            key = '/etc/letsencrypt/live/%s/privkey.pem' % site
        elif 'cert' in values and 'key' in values:
            # Custom certs, create them on disk
            cert = '/etc/nginx/ssl/%s.crt' % site
            key = '/etc/nginx/private/%s.key' % site

            ret['tls-terminator-%s-tls-cert' % site] = {
                'file.managed': [
                    {'name': cert},
                    {'contents': values.get('cert')},
                    {'require': [{'file': 'nginx-certificates-dir'}]},
                    {'watch_in': [{'service': 'nginx'}]},
                ]
            }

            ret['tls-terminator-%s-tls-key' % site] = {
                'file.managed': [
                    {'name': key},
                    {'contents': values.get('key')},
                    {'user': 'root'},
                    {'group': 'nginx'},
                    {'mode': '0640'},
                    {'show_changes': False},
                    {'require': [{'file': 'nginx-private-dir'}]},
                    {'watch_in': [{'service': 'nginx'}]},
                ]
            }
        else:
            # Using the default certs from the nginx state
            cert = '/etc/nginx/ssl/default.crt'
            key = '/etc/nginx/private/default.key'


        extra_server_config = values.get('extra_server_config', [])
        if isinstance(extra_server_config, dict):
            extra_server_config = [extra_server_config]

        # Add X-Request-Id header both ways if the nginx version supports it
        nginx_version_raw = __salt__['pillar.get']('nginx:version', '')
        nginx_version = tuple(int(num) for num in nginx_version_raw.split('.'))
        if nginx_version and nginx_version >= (1, 11, 0):
            extra_server_config.append({
                # Add to the response from the proxy
                'add_header': 'X-Request-Id $request_id always',
            })
            extra_server_config.append({
                # Add to the request before it reaches the proxy
                'proxy_set_header': 'X-Request-Id $request_id',
            })

        ret['tls-terminator-%s-nginx-site' % site] = {
            'file.managed': [
                {'name': '/etc/nginx/sites-enabled/%s' % site},
                {'source': 'salt://tls-terminator/nginx/site'},
                {'template': 'jinja'},
                {'require': [{'file': 'nginx-sites-enabled'}]},
                {'watch_in': [{'service': 'nginx'}]},
                {'context': {
                    'server_name': site,
                    'backends': parsed_backends,
                    'cert': cert,
                    'key': key,
                    'extra_server_config': extra_server_config,
                }}
            ]
        }


    for port in outgoing_firewall_ports:
        for family in ('ipv4', 'ipv6'):
            ret['tls-terminator-outgoing-port-%s-%s' % (port, family)] = {
                'firewall.append': [
                    {'chain': 'OUTPUT'},
                    {'family': family},
                    {'protocol': 'tcp'},
                    {'dport': port},
                    {'match': [
                        'comment',
                        'owner',
                    ]},
                    {'comment': 'tls-terminator: Allow outgoing to upstream'},
                    {'uid-owner': 'nginx'},
                    {'jump': 'ACCEPT'},
                ]
            }

    return ret


def get_upstream_identifier_for_backend(site, hostname, url):
    # Slashes are invalid in upstream identifiers, and we can't just replace them with _ or - since
    # that might cause conflicts with other urls (/api/old and /api-old would resolve to the same
    # upstream). We could use just a digest, but that would be bad for readability, thus we
    # construct a hybrid identifier incorporating the hostname, a slugified url and a truncated
    # digest of the url.
    url_slug = '-root' if url == '/' else slugify(url)
    url_digest = hashlib.sha256(url).hexdigest()[:6]
    return '%s-%s%s_%s' % (slugify(site), hostname, url_slug, url_digest)


def slugify(value):
    """
    Convert to ASCII if 'allow_unicode' is False. Convert spaces to hyphens.
    Remove characters that aren't alphanumerics, underscores, or hyphens.
    Convert to lowercase. Also strip leading and trailing whitespace.

    Compared to most other slugify functions this one also converts slashes to
    hyphens.
    """
    value = unicode(value)
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode('ascii')
    value = re.sub(r'[^\w\s/-]', '', value).strip().lower()
    return re.sub(r'[-\s/]+', '-', value)
