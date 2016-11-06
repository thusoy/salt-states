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
            backends['/'] = backend

        parsed_backends = {}
        for url, backend in backends.items():
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

            parsed_backends[url] = {
                'hostname': parsed_backend.hostname,
                'protocol': protocol,
                'port': port,
                'upstream_identifier': upstream_identifier,
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
