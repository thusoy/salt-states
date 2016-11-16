#!py

import hashlib
import socket
import re
import unicodedata
import urlparse
from collections import defaultdict


def run():
    """Create the states for the TLS-terminator backends."""

    sites = __pillar__.get('tls-terminator', {})

    ret = {
        "include": [
            "nginx"
        ]
    }

    outgoing_ipv4_firewall_ports = defaultdict(set)
    outgoing_ipv6_firewall_ports = defaultdict(set)

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

            # If backend is https it's going out over the network, thus allow it through
            # the firewall
            target_ip, target_port, remote, family = parse_backend(backend)
            if remote:
                if family in ('ipv4', 'both'):
                    outgoing_ipv4_firewall_ports[target_ip].add(port)
                if family in ('ipv6', 'both'):
                    outgoing_ipv6_firewall_ports[target_ip].add(port)

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
                elif upstream_hostname == 'request':
                    upstream_hostname = '$http_host'

            parsed_backends[url] = {
                'hostname': parsed_backend.hostname,
                'upstream_hostname': upstream_hostname,
                'protocol': protocol,
                'port': port,
                'upstream_identifier': upstream_identifier,
                'upstream_trust_root': upstream_trust_root,
                'pam_auth': backend_config.get('pam_auth', values.get('pam_auth')),
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

        https_redirect = '$server_name'
        if site.startswith('*'):
            https_redirect = '$http_host'

        client_max_body_size = values.get('client_max_body_size', '10m')

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
                    'https_redirect': https_redirect,
                    'client_max_body_size': client_max_body_size,
                    'extra_server_config': values.get('extra_server_config', {}),
                }}
            ]
        }


    for ruleset, family in [
        (outgoing_ipv4_firewall_ports, 'ipv4'),
        (outgoing_ipv6_firewall_ports, 'ipv6')]:
        for target_ip, ports in ruleset.items():
            port_key = 'dport' if len(ports) == 1 else 'dports'
            ret['tls-terminator-outgoing-port-%s-%s' % (port, family)] = {
                'firewall.append': [
                    {'chain': 'OUTPUT'},
                    {'family': family},
                    {'protocol': 'tcp'},
                    {'destination': target_ip},
                    {port_key: ','.join(str(port) for port in ports)},
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
    value = re.sub(r'[^\w\s/.\*-]', '', value).strip().lower()
    return re.sub(r'[-\s/]+', '-', value)


def parse_backend(url):
    # We classify it as external if either the address is specified as a hostname
    # and not an IP, and if it's an IP if it's outside the local range (127/8)
    parsed_url = urlparse.urlparse(url)

    packed_ip = get_packed_ip(parsed_url.hostname)
    port = parsed_url.port or (80 if parsed_url.scheme == 'http' else 443)
    remote = True
    normalized_ip = '0/0'
    family = 'both'

    if packed_ip and len(packed_ip) == 4:
        remote = packed_ip[0] != '\x7f'
        normalized_ip = socket.inet_ntop(socket.AF_INET, packed_ip)
        family = 'ipv4'
    elif packed_ip:
        ipv6_local_address = '\x00'*15 + '\x01'
        remote = packed_ip != ipv6_local_address
        normalized_ip = socket.inet_ntop(socket.AF_INET6, packed_ip)
        family = 'ipv6'

    return (normalized_ip, port, remote, family)


def get_packed_ip(address):
    packed_v4 = get_packed_ipv4(address)
    if packed_v4:
        return packed_v4
    else:
        return get_packed_ipv6(address)


def get_packed_ipv4(address):
    try:
        return socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            return socket.inet_aton(address)
        except socket.error:
            return None
    except socket.error:  # not a valid address
        return None


def get_packed_ipv6(address):
    try:
        return socket.inet_pton(socket.AF_INET6, address)
    except socket.error:  # not a valid address
        return None
