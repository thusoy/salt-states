#!py

import hashlib
import re
import socket
import textwrap
import unicodedata
import urlparse
from collections import defaultdict, namedtuple


Backend = namedtuple('Backend', 'normalized_ip port is_remote ip_family hostname path scheme server_arguments')


def run():
    """Create the states for the TLS-terminator backends."""
    return build_state(__pillar__.get('tls-terminator', {}),
        nginx_version=__salt__['pillar.get']('nginx:version', '0.0.0'))


def build_state(sites, nginx_version='0.0.0'):
    ret = {
        "include": [
            "nginx"
        ]
    }

    has_any_acme_sites = False

    outgoing_ipv4_firewall_ports = defaultdict(set)
    outgoing_ipv6_firewall_ports = defaultdict(set)

    rate_limit_zones = []
    error_pages = get_default_error_pages()
    error_pages.update(normalize_error_pages(sites))
    global_headers = sites.pop('add_headers', {})

    ret.update(build_security_header_maps())

    for site, site_config in sites.items():
        backends = normalize_backends(site, site_config)
        site_headers = dict(global_headers)
        site_headers.update(site_config.get('add_headers', {}))
        add_security_headers(site_headers)
        parsed_backends = {}
        upstreams = {}
        for url, backend_config in backends.items():
            # If backend is https it's going out over the network, thus allow it through
            # the firewall
            backend_upstreams = backend_config.get('upstreams', [])
            if not backend_upstreams:
                backend_upstreams = [backend_config['upstream']]

            for upstream in backend_upstreams:
                backend = parse_backend(upstream)
                if backend.is_remote:
                    if backend.ip_family in ('ipv4', 'both'):
                        outgoing_ipv4_firewall_ports[backend.normalized_ip].add(backend.port)
                    if backend.ip_family in ('ipv6', 'both'):
                        outgoing_ipv6_firewall_ports[backend.normalized_ip].add(backend.port)

            states, backend_context, upstream = build_backend_context(site, site_config,
                backend_config, nginx_version)

            backend_headers = dict(site_headers)
            backend_headers.update(backend_config.get('add_headers', {}))
            backend_context['headers'] = backend_headers

            upstreams[upstream['identifier']] = upstream
            parsed_backends[url] = backend_context
            ret.update(states)

        error_states, error_pages = build_site_error_pages(site, site_config, error_pages)
        ret.update(error_states)
        rate_limit_zones.extend(build_rate_limit_zones(site_config))

        cert, key, is_acme, cert_states = build_tls_certs_for_site(site, site_config)
        ret.update(cert_states)
        if is_acme:
            has_any_acme_sites = True

        https_redirect = '$server_name'
        if site.startswith('*'):
            https_redirect = '$http_host'

        extra_server_config = site_config.get('extra_server_config', [])
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
                    'listen_parameters': site_config.get('listen_parameters', ''),
                    'headers': site_headers,
                    'backends': parsed_backends,
                    'cert': cert,
                    'key': key,
                    'https_redirect': https_redirect,
                    'client_max_body_size': site_config.get('client_max_body_size', '10m'),
                    'extra_server_config': extra_server_config,
                    'extra_locations': site_config.get('extra_locations', {}),
                    'redirect': site_config.get('redirect'),
                    'error_pages': error_pages,
                    'upstreams': upstreams,
                }}
            ]
        }

    ret.update(build_firewall_states(outgoing_ipv4_firewall_ports, outgoing_ipv6_firewall_ports))

    ret['tls-terminator-rate-limit-zones'] = {
        'file.managed': [
            {'name': '/etc/nginx/http-config/tls-terminator.rate_limit_zones.conf'},
            {'source': 'salt://tls-terminator/rate_limit_zones.conf'},
            {'template': 'jinja'},
            {'context': {
                'rate_limit_zones': rate_limit_zones,
            }},
            {'require': [{'file': 'nginx-http-config'}]},
            {'watch_in': [{'service': 'nginx'}]},
        ]
    }

    if has_any_acme_sites:
        ret['include'].append('certbot')

    return ret


def normalize_error_pages(site_config):
    normalized = {}
    error_pages = site_config.pop('error_pages', {})
    for error_code, content in error_pages.items():
        if not isinstance(content, dict):
            content = {
                'content_type': 'text/html',
                'content': content,
            }
        normalized[int(error_code)] = content

    return normalized


def build_security_header_maps():
    return {
        'tls-terminator-security-header-maps': {
            'file.managed': [
                {'name': '/etc/nginx/http-config/tls-terminator.security_header_maps.conf'},
                {'source': 'salt://tls-terminator/security_header_maps.conf'},
                {'require': [{'file': 'nginx-http-config'}]},
                {'watch_in': [{'service': 'nginx'}]},
            ]
        }
    }


def add_security_headers(site_headers):
    default_security_headers = {
        'Strict-Transport-Security': '$tlst_strict_transport_security',
        'X-Frame-Options': '$tlst_frame_options',
        'X-Xss-Protection': '$tlst_xss_protection',
        'X-Content-Type-Options': '$tlst_content_type_options',
    }
    for header, value in default_security_headers.items():
        if header not in site_headers:
            site_headers[header] = value


def normalize_backends(site, site_config):
    backend = site_config.get('backend')
    backends = site_config.get('backends', {})
    redirect = site_config.get('redirect')
    required_properties_given = len([prop for prop in (backend, backends, redirect) if prop])
    if required_properties_given != 1:
        raise ValueError('TLS-terminator site "%s" has none or too many of the required '
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
        if 'upstream' in backends[url] and 'upstreams' in backends[url]:
            raise ValueError("TLS-terminator site '%s' had both upstream and upstreams" % site)

    # Add backends only specified in rate limit rules
    for url, limits in site_config.get('rate_limit', {}).get('backends', {}).items():
        backend = backends.get(url)
        if not backend:
            backend = dict(backends['/'].items())
            backends[url] = backend

        rule = ['zone=%s' % limits['zone']]
        burst = limits.get('burst')
        if burst:
            rule.append('burst=%d' % burst)
        nodelay = limits.get('nodelay', True)
        if nodelay:
            rule.append('nodelay')
        backend['rate_limit'] = ' '.join(rule)

    return backends


def build_backend_context(site, site_config, backend_config, nginx_version):
    upstream = build_upstream(site, backend_config)
    upstream_identifier = upstream['identifier']

    if len(upstream['servers']) == 1:
        upstream_hostname = upstream['servers'][0]['hostname']
    else:
        upstream_hostname = 'site'

    states = {}

    upstream_trust_root = '/etc/nginx/ssl/all-certs.pem'
    if 'upstream_trust_root' in backend_config:
        upstream_trust_root = '/etc/nginx/ssl/%s-root.pem' % upstream_identifier
        states['tls-terminator-upstream-%s-trust-root' % upstream_identifier] = {
            'file.managed': [
                {'name': upstream_trust_root},
                {'contents': backend_config.get('upstream_trust_root')},
                {'require_in': [
                    {'file': 'tls-terminator-%s-nginx-site' % site},
                ]},
            ]
        }

    # Set default upstream Host header to the hostname if the upstream
    # is a hostname, otherwise the name of the site
    if 'upstream_hostname' in backend_config or 'upstream_hostname' in site_config:
        upstream_hostname = backend_config.get('upstream_hostname',
            site_config.get('upstream_hostname'))
    if upstream_hostname == 'site':
        upstream_hostname = site
    elif upstream_hostname == 'request':
        upstream_hostname = '$http_host'

    extra_location_config = backend_config.get('extra_location_config', [])
    if isinstance(extra_location_config, dict):
        extra_location_config = [extra_location_config]

    # Add X-Request-Id header both ways if the nginx version supports it
    nginx_version = tuple(int(num) for num in nginx_version.split('.'))
    if nginx_version and nginx_version >= (1, 11, 0):
        extra_location_config.append({
            # Add to the response from the proxy
            'add_header': 'X-Request-Id $request_id always',
        })
        extra_location_config.append({
            # Add to the request before it reaches the proxy
            'proxy_set_header': 'X-Request-Id $request_id',
        })

    return states, {
        'upstream_hostname': upstream_hostname,
        'protocol': upstream['scheme'],
        'upstream_identifier': upstream_identifier,
        'upstream_trust_root': upstream_trust_root,
        'pam_auth': backend_config.get('pam_auth', site_config.get('pam_auth')),
        'extra_location_config': extra_location_config,
        'rate_limit': backend_config.get('rate_limit'),
    }, upstream


def build_upstream(site, backend_config):
    upstreams = backend_config.get('upstreams', [])
    if not upstreams:
        upstreams = [backend_config['upstream']]
    upstreams.sort()
    upstream = {
        'servers': [],
        'keepalive': backend_config.get('upstream_keepalive', 8),
        'least_conn': backend_config.get('upstream_least_conn', False),
    }
    upstream_identifier = None
    for server in upstreams:
        parsed_backend = parse_backend(server)
        if upstream_identifier is None:
            upstream_identifier = get_upstream_identifier_for_backend(site, parsed_backend)
        upstream['servers'].append({
            'hostname': parsed_backend.hostname,
            'port': parsed_backend.port,
            'arguments': parsed_backend.server_arguments,
        })
    upstream['identifier'] = upstream_identifier
    upstream['scheme'] = parsed_backend.scheme
    return upstream


def build_tls_certs_for_site(site, site_config):
    is_acme = site_config.get('acme')
    states = {}
    if is_acme:
        # The actual certs will be managed by the certbot state (or equivalent)
        cert = '/etc/letsencrypt/live/%s/fullchain.pem' % site
        key = '/etc/letsencrypt/live/%s/privkey.pem' % site

    elif 'cert' in site_config and 'key' in site_config:
        # Custom certs, create them on disk
        cert = '/etc/nginx/ssl/%s.crt' % site
        key = '/etc/nginx/private/%s.key' % site

        states['tls-terminator-%s-tls-cert' % site] = {
            'file.managed': [
                {'name': cert},
                {'contents': site_config.get('cert')},
                {'require': [{'file': 'nginx-certificates-dir'}]},
                {'watch_in': [{'service': 'nginx'}]},
            ]
        }

        states['tls-terminator-%s-tls-key' % site] = {
            'file.managed': [
                {'name': key},
                {'contents': site_config.get('key')},
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

    return cert, key, is_acme, states


def build_site_error_pages(site, site_config, default_error_pages):
    states = {}
    error_pages = dict(default_error_pages.items())
    error_pages.update(normalize_error_pages(site_config))

    for error_code, content in error_pages.items():
        states['tls-terminator-%s-error-page-%d' % (site, error_code)] = {
            'file.managed': [
                {'name': '/etc/nginx/html/%d-%s' % (error_code, site)},
                {'contents': content['content']},
                {'makedirs': True},
                {'template': 'jinja'},
                {'context': {
                    'site': site,
                }},
            ]
        }

    return states, error_pages


def build_firewall_states(outgoing_ipv4_firewall_ports, outgoing_ipv6_firewall_ports):
    states = {}
    for ruleset, family in [
        (outgoing_ipv4_firewall_ports, 'ipv4'),
        (outgoing_ipv6_firewall_ports, 'ipv6')]:
        for target_ip, ports in sorted(ruleset.items()):
            for port_set in get_port_sets(ports):
                states['tls-terminator-outgoing-%s-port-%s' % (family, port_set)] = {
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
    return states


def build_rate_limit_zones(site_config):
    zones = []
    rate_limit = site_config.get('rate_limit', {})
    if not rate_limit:
        return zones

    for zone_name, config in sorted(rate_limit.get('zones', {}).items()):
        key = config.get('key', '$binary_remote_addr')
        size = config.get('size', '1m')
        rate = config['rate']
        zones.append('%s zone=%s:%s rate=%s' % (key, zone_name, size, rate))

    return zones


def get_upstream_identifier_for_backend(site, parsed_backend_url):
    # Balance the need for unique upstream identifiers with readability by
    # combining the hostname with a slugified url and a truncated digest of the
    # url.
    backend_path = parsed_backend_url.path
    url_slug = '-root' if backend_path == '/' else slugify(backend_path)
    url_digest = hashlib.sha256('%d:%s' % (parsed_backend_url.port, backend_path)).hexdigest()[:6]
    return '%s-%s%s_%s' % (slugify(site), parsed_backend_url.hostname, url_slug, url_digest)


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
    url_parts = url.split(None, 1)
    if len(url_parts) == 2:
        url, arguments = url_parts
    else:
        url = url_parts[0]
        arguments = None
    parsed_url = urlparse.urlparse(url)

    packed_ip = get_packed_ip(parsed_url.hostname)
    port = parsed_url.port or (80 if parsed_url.scheme == 'http' else 443)
    is_remote = True
    normalized_ip = '0/0'
    family = 'both'

    if packed_ip and len(packed_ip) == 4:
        is_remote = packed_ip[0] != '\x7f'
        normalized_ip = socket.inet_ntop(socket.AF_INET, packed_ip)
        family = 'ipv4'
    elif packed_ip:
        ipv6_local_address = '\x00'*15 + '\x01'
        is_remote = packed_ip != ipv6_local_address
        normalized_ip = socket.inet_ntop(socket.AF_INET6, packed_ip)
        family = 'ipv6'

    return Backend(normalized_ip,
        port,
        is_remote,
        family,
        parsed_url.hostname,
        parsed_url.path,
        parsed_url.scheme,
        arguments,
    )


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


def get_default_error_pages():
    return {
        429: {
            'content_type': 'text/html',
            'content': textwrap.dedent('''\
                <!doctype html>
                <html lang="en">
                <meta charset="utf-8">
                <title>Too many requests to {{ site }}</title>
                <h1>We've detected too many requests to {{ site }}</h1>
                <p>
                    We're terribly sorry for this, but we seem to have detected too many requests to
                    {{ site }} from your network recently. Please try again in a little while.
                </p>

                <p>
                    <small>Details: 429 (too many requests)</small>
                </p>
            ''')
        },
        502: {
            'content_type': 'text/html',
            'content': textwrap.dedent('''\
                <!doctype html>
                <html lang="en">
                <meta charset="utf-8">
                <title>{{ site }} failed</title>
                <h1>Failed to load {{ site }}</h1>
                <p>
                    We're very sorry, but {{ site }} couldn't be reached at the moment. Please try
                    again in a little while.
                </p>

                <p>
                    <small>Details: 502 (bad gateway)</small>
                </p>
            '''),
        },
        504: {
            'content_type': 'text/html',
            'content': textwrap.dedent('''\
                <!doctype html>
                <html lang="en">
                <meta charset="utf-8">
                <title>{{ site }} unreachable</title>
                <h1>{{ site }} unreachable</h1>

                <p>
                    We're terribly sorry for this, but {{ site }} timed out while loading. We're
                    not quite sure what the issue is yet, but we're working on it. Try again in
                    a little while.
                </p>

                <p>
                    <small>Details: 504 (gateway timeout)</small>
                </p>
            '''),
        }
    }
