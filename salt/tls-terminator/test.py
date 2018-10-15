import imp
import os

module = imp.load_source('tls_terminator', os.path.join(os.path.dirname(__file__), 'init.sls'))

def test_is_external_backend():
    uut = module.parse_backend
    assert uut('https://example.com') == ('0/0', 443, True, 'both')
    assert uut('https://example.com:8000') == ('0/0', 8000, True, 'both')
    assert uut('https://10.10.10.10') == ('10.10.10.10', 443, True, 'ipv4')
    assert uut('https://10.10.10.10:5000') == ('10.10.10.10', 5000, True, 'ipv4')
    assert uut('http://example.com') == ('0/0', 80, True, 'both')
    assert uut('http://10.10.10.10') == ('10.10.10.10', 80, True, 'ipv4')
    assert uut('https://[2001:0db8:85a3:08d3:1319:8a2e:0370:7344]:8000') == \
        ('2001:db8:85a3:8d3:1319:8a2e:370:7344', 8000, True, 'ipv6')

    assert uut('https://127.0.0.1') == ('127.0.0.1', 443, False, 'ipv4')
    assert uut('http://127.0.0.1') == ('127.0.0.1', 80, False, 'ipv4')
    assert uut('https://127.43.25.21') == ('127.43.25.21', 443, False, 'ipv4')
    assert uut('http://[::1]') == ('::1', 80, False, 'ipv6')
    assert uut('https://[::1]:5000') == ('::1', 5000, False, 'ipv6')


def test_get_port_sets():
    uut = module.get_port_sets
    assert uut([]) == []
    assert uut([1]) == ['1']
    assert uut([1, 2]) == ['1:2']
    assert uut([1, 2, 4]) == ['1:2,4']
    assert uut([1, 3,4,5, 7]) == ['1,3:5,7']
    assert uut(range(0, 31, 2)) == ['0,2,4,6,8,10,12,14,16,18,20,22,24,26,28', '30']


def test_build_state():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
        }
    })
    backends = get_backends(state['tls-terminator-example.com-nginx-site'])
    assert len(backends) == 1
    assert backends['/']['hostname'] == '127.0.0.1'
    assert backends['/']['port'] == 5000
    assert 'certbot' not in state['include']
    rate_limits = merged(state['tls-terminator-rate-limit-zones']['file.managed'])
    assert len(rate_limits['context']['rate_limit_zones']) == 0


def test_build_state_aliases():
    short = {
        'example.com': {'backend': 'http://127.0.0.1:5000'},
    }
    medium = {
        'example.com': {
            'backends': {
                '/': 'http://127.0.0.1:5000',
            }
        }
    }
    full = {
        'example.com': {
            'backends': {
                '/': {
                    'upstream': 'http://127.0.0.1:5000',
                }
            }
        }
    }
    uut = module.build_state
    assert uut(short) == uut(medium) == uut(full)


def test_build_acme_state():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
            'acme': True,
        }
    })
    assert 'certbot' in state['include']


def test_build_custom_tls_state():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
            'cert': 'FOOCERT',
            'key': 'FOOKEY',
        }
    })
    cert = state['tls-terminator-example.com-tls-cert']
    key = state['tls-terminator-example.com-tls-key']
    assert merged(cert['file.managed'])['contents'] == 'FOOCERT'
    assert merged(key['file.managed'])['contents'] == 'FOOKEY'
    assert 'certbot' not in state['include']


def test_build_outgoing_ip():
    state = module.build_state({
        'example.com': {
            'backend': 'http://1.1.1.1',
        }
    })

    assert 'tls-terminator-outgoing-ipv4-port-443' not in state
    firewall_v4 = merged(state['tls-terminator-outgoing-ipv4-port-80']['firewall.append'])
    assert firewall_v4['family'] == 'ipv4'
    assert firewall_v4['dports'] == '80'
    assert firewall_v4['destination'] == '1.1.1.1'


def test_build_outgoing_hostname():
    state = module.build_state({
        'example.com': {
            'backend': 'https://backend.example.com',
        }
    })

    assert 'tls-terminator-outgoing-ipv4-port-80' not in state
    firewall_v4 = merged(state['tls-terminator-outgoing-ipv4-port-443']['firewall.append'])
    assert firewall_v4['family'] == 'ipv4'
    assert firewall_v4['dports'] == '443'
    assert firewall_v4['destination'] == '0/0'


def test_set_rate_limits():
    state = module.build_state({
        'example.com': {
            'rate_limit': {
                'zones': {
                    'default': {
                        'size': '10m',
                        'rate': '60r/m',
                        'key': '$cookie_session',
                    },
                    'sensitive': {
                        'rate': '10r/m',
                    }
                },
                'backends': {
                    '/': {
                        'zone': 'default',
                        'burst': 30,
                    },
                    '/login': {
                        'zone': 'sensitive',
                        'burst': 5,
                        'nodelay': False,
                    }
                }
            },
            'backend': 'http://127.0.0.1:5000',
        }
    })

    nginx_site = state['tls-terminator-example.com-nginx-site']
    backends = get_backends(nginx_site)
    assert len(backends) == 2
    assert backends['/']['rate_limit'] == 'zone=default burst=30 nodelay'
    assert backends['/login']['rate_limit'] == 'zone=sensitive burst=5'

    rate_limits = merged(state['tls-terminator-rate-limit-zones']['file.managed'])
    assert rate_limits['context']['rate_limit_zones'] == [
        '$cookie_session zone=default:10m rate=60r/m',
        '$binary_remote_addr zone=sensitive:1m rate=10r/m',
    ]


def get_backends(state_nginx_site):
    return merged(state_nginx_site['file.managed'])['context']['backends']


def merged(dict_list):
    '''Merges a salt-style list of dicts into a single dict'''
    merged = {}
    for dictionary in dict_list:
        merged.update(dictionary)
    return merged
