import imp
import os
from collections import OrderedDict

import pytest


module = imp.load_source('tls_terminator', os.path.join(os.path.dirname(__file__), 'init.sls'))

def test_is_external_backend():
    def uut(backend):
        return module.parse_backend(backend)[:4]

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
    assert backends['/']['upstream_identifier'].startswith('example.com-127.0.0.1_')
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
    multiple = {
        'example.com': {
            'backends': {
                '/': {
                    'upstreams': [
                        'http://127.0.0.1:5000',
                    ]
                }
            }
        }
    }
    uut = module.build_state
    assert uut(short) == uut(medium) == uut(full) == uut(multiple)


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
    cert = state['tls-terminator-example.com-certs-1-cert']
    key = state['tls-terminator-example.com-certs-1-key']
    assert merged(cert['file.managed'])['contents'] == 'FOOCERT'
    assert merged(key['file.managed'])['contents'] == 'FOOKEY'
    assert 'certbot' not in state['include']


def test_build_custom_tls_pillar_state():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
            'cert_pillar': 'some:pillar:key',
            'key_pillar': 'other:pillar:key',
        }
    })
    cert = state['tls-terminator-example.com-certs-1-cert']
    key = state['tls-terminator-example.com-certs-1-key']
    assert merged(cert['file.managed'])['contents_pillar'] == 'some:pillar:key'
    assert merged(key['file.managed'])['contents_pillar'] == 'other:pillar:key'
    assert 'certbot' not in state['include']


def test_build_multiple_tls_pillar_state():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
            'certs': [{
                'cert_pillar': 'pillar:rsa:cert',
                'key_pillar': 'pillar:rsa:key',
            }, {
                'cert_pillar': 'pillar:ecdsa:cert',
                'key_pillar': 'pillar:ecdsa:key',
            }],
        }
    })
    cert_1 = state['tls-terminator-example.com-certs-1-cert']
    key_1 = state['tls-terminator-example.com-certs-1-key']
    cert_2 = state['tls-terminator-example.com-certs-2-cert']
    key_2 = state['tls-terminator-example.com-certs-2-key']
    assert merged(cert_1['file.managed'])['contents_pillar'] == 'pillar:rsa:cert'
    assert merged(key_1['file.managed'])['contents_pillar'] == 'pillar:rsa:key'
    assert merged(cert_2['file.managed'])['contents_pillar'] == 'pillar:ecdsa:cert'
    assert merged(key_2['file.managed'])['contents_pillar'] == 'pillar:ecdsa:key'
    assert 'certbot' not in state['include']


def test_build_outgoing_firewall_rules():
    state = module.build_state({
        'example.com': {
            'backend': 'http://1.1.1.1',
        },
        'foo.com': {
            'backend': 'http://2.2.2.2:8000',
        },
        'bar.com': {
            'backend': 'https://app.bar.com',
        },
    })

    assert 'tls-terminator-outgoing-ipv4-port-443' not in state
    example_v4 = merged(state['tls-terminator-outgoing-ipv4-to-1.1.1.1-port-80']['firewall.append'])
    assert example_v4['family'] == 'ipv4'
    assert example_v4['dports'] == '80'
    assert example_v4['destination'] == '1.1.1.1'

    foo_v4 = merged(state['tls-terminator-outgoing-ipv4-to-2.2.2.2-port-8000']['firewall.append'])
    assert foo_v4['family'] == 'ipv4'
    assert foo_v4['dports'] == '8000'
    assert foo_v4['destination'] == '2.2.2.2'

    bar_v4 = merged(state['tls-terminator-outgoing-ipv4-to-0/0-port-443']['firewall.append'])
    assert bar_v4['family'] == 'ipv4'
    assert bar_v4['dports'] == '443'
    assert bar_v4['destination'] == '0/0'

    bar_v6 = merged(state['tls-terminator-outgoing-ipv6-to-0/0-port-443']['firewall.append'])
    assert bar_v6['family'] == 'ipv6'
    assert bar_v6['dports'] == '443'
    assert bar_v6['destination'] == '0/0'


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
    # Should share upstream
    assert backends['/login']['upstream_identifier'] == backends['/']['upstream_identifier']
    assert len(merged(nginx_site['file.managed'])['context']['upstreams']) == 1

    rate_limits = merged(state['tls-terminator-rate-limit-zones']['file.managed'])
    assert rate_limits['context']['rate_limit_zones'] == [
        '$cookie_session zone=default:10m rate=60r/m',
        '$binary_remote_addr zone=sensitive:1m rate=10r/m',
    ]

    assert 'tls-terminator-example.com-error-page-429' in state


def test_custom_error_pages():
    pillar = OrderedDict({
        'error_pages': {
            '429': '429 loading {{ site }}',
            502: {
                'content_type': 'application/json',
                'content': '{"error": 502, "site": "{{ site }}"}',
            },
        },
        'test.com': {
            'backend': 'http://127.0.0.1:5001',
            'error_pages': {
                502: '<p>Backend stumbled</p>',
            },
        },
    })
    # Add example.com later to ensure test.com is processed first to expose ordering bugs
    pillar['example.com'] = {
        'backend': 'http://127.0.0.1:5000',
    }

    state = module.build_state(pillar)

    def error_page(site, error_code):
        error_state = state['tls-terminator-%s-error-page-%d' % (site, error_code)]
        file_state = merged(error_state['file.managed'])
        return file_state

    nginx_site = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])
    error_pages = nginx_site['context']['error_pages']
    assert len(error_pages) == 3 # the two defaults plus 502
    assert error_page('example.com', 429)['contents'] == '429 loading {{ site }}'
    assert error_page('example.com', 502)['contents'] == '{"error": 502, "site": "{{ site }}"}'
    assert error_page('example.com', 504)['contents'].startswith('<!doctype html>')
    assert error_page('test.com', 429)['contents'] == '429 loading {{ site }}'
    assert error_page('test.com', 502)['contents'] == '<p>Backend stumbled</p>'


def test_isolatest_site_upstreams():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000',
        },
        'otherexample.com': {
            'backend': 'http://127.0.0.1:5001',
        },
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    assert len(context['upstreams']) == 1


def test_upstream_with_url():
    state = module.build_state({
        'example.com': {
            'backend': 'http://127.0.0.1:5000/path',
        }
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    upstreams = context['upstreams']
    assert len(upstreams) == 1
    assert not any('/' in identifier for identifier in upstreams)


def test_upstream_port_only_difference():
    state = module.build_state({
        'example.com': {
            'backends': {
                '/': 'http://127.0.0.1:5000',
                '/path': 'http://127.0.0.1:5001',
            }
        }
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    upstreams = context['upstreams']
    assert len(upstreams) == 2


def test_upstream_set_trust_root():
    state = module.build_state({
        'example.com': {
            'backends': {
                '/': {
                    'upstream': 'https://10.10.10.10',
                    'upstream_trust_root': 'some upstream cert',
                }
            }
        }
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    upstream_identifier = context['upstreams'].keys()[0]
    expected_trust_root_path = '/etc/nginx/ssl/%s-root.pem' % upstream_identifier
    assert context['backends']['/']['upstream_trust_root'] == expected_trust_root_path
    assert 'tls-terminator-upstream-%s-trust-root' % upstream_identifier in state


def test_invalid_config():
    with pytest.raises(ValueError):
        module.build_state({
            'example.com': {}
        })

    with pytest.raises(ValueError):
        module.build_state({
            'example.com': {
                'backend': 'http://127.0.0.1',
                'backends': {
                    '/': 'http://127.0.0.1',
                },
            }
        })

    with pytest.raises(ValueError):
        module.build_state({
            'example.com': {
                'backends': {
                    '/': {
                        'upstream': 'http://10.10.10.10',
                        'upstreams': ['http://10.10.10.11'],
                    }
                }
            }
        })


def test_multiple_upstreams():
    state = module.build_state({
        'example.com': {
            'backends': {
                '/': {
                    'upstreams': [
                        'http://10.10.10.10:5000 weight=2',
                        'http://10.10.10.11:5000'
                    ],
                    'upstream_keepalive': 16,
                    'upstream_least_conn': True,
                },
                '/path': {
                    'upstream': 'http://10.10.10.12:5001',
                }
            }
        }
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    upstreams = context['upstreams']
    assert upstreams['example.com-10.10.10.10_2d957d'] == {
        'identifier': 'example.com-10.10.10.10_2d957d',
        'servers': [{
            'hostname': '10.10.10.10',
            'port': 5000,
            'arguments': 'weight=2',
        }, {
            'hostname': '10.10.10.11',
            'port': 5000,
            'arguments': None,
        }],
        'keepalive': 16,
        'least_conn': True,
        'scheme': 'http',
    }


def test_add_headers():
    state = module.build_state({
        'add_headers': {
            'Expect-CT': 'max-age=60, report-uri=https://example.com/.report-uri/expect-ct',
        },
        'example.com': {
            'backends': {
                '/': {
                    'upstream': 'http://127.0.0.1:5000',
                },
                '/other': {
                    'upstream': 'http://127.0.0.1:5001',
                    'add_headers': {
                        'X-Frame-Options': 'sameorigin',
                    }
                }
            },
            'add_headers': {
                'Referrer-Policy': 'strict-origin-when-cross-origin',
                'Expect-CT': '',
            }
        },
    })
    context = merged(state['tls-terminator-example.com-nginx-site']['file.managed'])['context']
    default_security_headers = (
        'Strict-Transport-Security',
        'X-Xss-Protection',
        'X-Content-Type-Options',
        'X-Frame-Options',
    )
    for header in default_security_headers:
        assert header in context['headers']
    assert 'Expect-CT' in context['headers']
    assert 'Referrer-Policy' in context['headers']
    assert context['backends']['/other']['headers']['X-Frame-Options'] == 'sameorigin'
    assert context['headers']['Expect-CT'] == ''


def get_backends(state_nginx_site):
    return merged(state_nginx_site['file.managed'])['context']['backends']


def merged(dict_list):
    '''Merges a salt-style list of dicts into a single dict'''
    merged_dict = {}
    for dictionary in dict_list:
        merged_dict.update(dictionary)
    return merged_dict
