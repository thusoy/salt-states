#!py

import urlparse


def run():
    """Create the states for the TLS-terminator backends."""

    sites = __pillar__.get('tls-terminator', {})


    ret = {
        "include": [
            ".pillar_check",
            "nginx"
        ]
    }

    default_cert = __salt__['pillar.get']('nginx:default_cert')
    default_key = __salt__['pillar.get']('nginx:default_key')

    outgoing_firewall_ports = set()

    for site, values in sites.items():
        backend = values.get('backend')
        if not backend:
            raise ValueError('TLS-terminator site "%s" is missing required property backend' %
                site)
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

        cert = values.get('cert', default_cert)
        key = values.get('key', default_key)
        normalized_backend = '//' + backend if not '://' in backend else backend
        parsed_backend = urlparse.urlparse(normalized_backend)
        backend_protocol = parsed_backend.scheme or 'http'
        backend_port = parsed_backend.port or ('443' if backend_protocol == 'https' else 80)
        backend_without_protocol = parsed_backend.hostname

        # If backend is https it's going out over the network, thus allow it through
        # the firewall
        if backend_protocol == 'https':
            outgoing_firewall_ports.add(backend_port)

        ret['tls-terminator-%s-nginx-site' % site] = {
            'file.managed': [
                {'name': '/etc/nginx/sites-enabled/%s' % site},
                {'source': 'salt://tls-terminator/nginx/site'},
                {'template': 'jinja'},
                {'require': [{'file': 'nginx-sites-enabled'}]},
                {'watch_in': [{'service': 'nginx'}]},
                {'context': {
                    'server_name': site,
                    'backend': backend_without_protocol,
                    'backend_protocol': backend_protocol,
                    'backend_port': backend_port,
                }}
            ]
        }

        ret['tls-terminator-%s-tls-cert' % site] = {
            'file.managed': [
                {'name': '/etc/nginx/ssl/%s.crt' % site},
                {'contents': cert},
                {'require': [{'file': 'nginx-certificates-dir'}]},
                {'watch_in': [{'service': 'nginx'}]},
            ]
        }

        ret['tls-terminator-%s-tls-key' % site] = {
            'file.managed': [
                {'name': '/etc/nginx/private/%s.key' % site},
                {'contents': key},
                {'user': 'root'},
                {'group': 'nginx'},
                {'mode': '0640'},
                {'show_diff': False},
                {'require': [{'file': 'nginx-private-dir'}]},
                {'watch_in': [{'service': 'nginx'}]},
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
