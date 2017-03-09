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

    has_any_acme_sites = False

    outgoing_ipv4_firewall_ports = defaultdict(set)
    outgoing_ipv6_firewall_ports = defaultdict(set)

    for site, values in sites.items():
        backend = values.get('backend')
        backends = values.get('backends', {})
        redirect = values.get('redirect')
        required_properties_given = len([prop for prop in (backend, backends, redirect) if prop])
        if required_properties_given != 1:
            raise ValueError('TLS-terminator site "%s" is has none or too many of the required '
                'properties backend/backends/redirect' % site)

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
            port = parsed_backend.port or (443 if protocol == 'https' else 80)
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

            extra_location_config = backend_config.get('extra_location_config', [])
            if isinstance(extra_location_config, dict):
                extra_location_config = [extra_location_config]

            # Add X-Request-Id header both ways if the nginx version supports it
            nginx_version_raw = __salt__['pillar.get']('nginx:version', '0.0.0')
            nginx_version = tuple(int(num) for num in nginx_version_raw.split('.'))
            if nginx_version and nginx_version >= (1, 11, 0):
                extra_location_config.append({
                    # Add to the response from the proxy
                    'add_header': 'X-Request-Id $request_id always',
                })
                extra_location_config.append({
                    # Add to the request before it reaches the proxy
                    'proxy_set_header': 'X-Request-Id $request_id',
                })

            parsed_backends[url] = {
                'hostname': parsed_backend.hostname,
                'upstream_hostname': upstream_hostname,
                'protocol': protocol,
                'port': port,
                'upstream_identifier': upstream_identifier,
                'upstream_trust_root': upstream_trust_root,
                'pam_auth': backend_config.get('pam_auth', values.get('pam_auth')),
                'extra_location_config': extra_location_config,
            }

        site_504_page = [
            {'name': '/etc/nginx/html/504-' + site + '.html'},
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

            has_any_acme_sites = True
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

        extra_server_config = values.get('extra_server_config', [])
        if isinstance(extra_server_config, dict):
            extra_server_config = [extra_server_config]

        ret['tls-terminator-%s-nginx-site' % site] = {
            'file.managed': [
                {'name': '/etc/nginx/sites-enabled/%s' % site},
                {'source': 'salt://tls-terminator/nginx/site'},
                {'template': 'jinja'},
                {'require': [{'file': 'nginx-sites-enabled-dir'}]},
                {'watch_in': [{'service': 'nginx'}]},
                {'context': {
                    'server_name': site,
                    'listen_parameters': values.get('listen_parameters', ''),
                    'backends': parsed_backends,
                    'cert': cert,
                    'key': key,
                    'https_redirect': https_redirect,
                    'client_max_body_size': client_max_body_size,
                    'extra_server_config': extra_server_config,
                    'extra_locations': values.get('extra_locations', {}),
                    'redirect': redirect,
                }}
            ]
        }


    for ruleset, family in [
        (outgoing_ipv4_firewall_ports, 'ipv4'),
        (outgoing_ipv6_firewall_ports, 'ipv6')]:
        for target_ip, ports in sorted(ruleset.items()):
            for port_set in get_port_sets(ports):
                ret['tls-terminator-outgoing-%s-port-%s' % (family, port_set)] = {
                    'firewall.append': [
                        {'chain': 'OUTPUT'},
                        {'family': family},
                        {'protocol': 'tcp'},
                        {'destination': target_ip},
                        {'dports': port_set},
                        {'match': [
                            'comment',
                            'owner',
                        ]},
                        {'comment': 'tls-terminator: Allow outgoing to upstream'},
                        {'uid-owner': 'nginx'},
                        {'jump': 'ACCEPT'},
                    ]
                }

    if has_any_acme_sites:
        ret['include'].append('certbot')

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


def get_port_sets(ports):
    '''
    Compress the set of ports down to ranges acceptable by iptables' multiport.

    The return value will be a list of strings, using the minimal amout of ports.
    This is needed since the multiport option to iptables only supports 15 different
    ports.
    '''
    all_ports = []
    start_of_range = None
    previous_port = None
    for port in sorted(ports):
        if previous_port is not None and previous_port == port - 1:
            if start_of_range is None:
                start_of_range = previous_port
        else:
            if start_of_range is not None:
                all_ports.append((start_of_range, previous_port))
                start_of_range = None
            elif previous_port is not None:
                all_ports.append(previous_port)
        previous_port = port
    if start_of_range:
        all_ports.append((start_of_range, previous_port))
    elif previous_port:
        all_ports.append(previous_port)

    sets = []
    this_set = []
    set_count = 0
    for item in all_ports:
        weight = 1 if isinstance(item, int) else 2
        if set_count <= 15 - weight:
            this_set.append(format_item(item))
            set_count += weight
        else:
            sets.append(','.join(this_set))
            this_set = [format_item(item)]
            set_count = weight
    if this_set:
        sets.append(','.join(this_set))

    return sets


def format_item(item):
    if isinstance(item, int):
        return str(item)
    else:
        return '%d:%d' % item
