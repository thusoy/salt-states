import imp
import os

import mock


module = imp.load_source('acme_dns', os.path.join(os.path.dirname(__file__), 'ext_pillar.py'))


def test_has_access():
    uut = module._has_access
    assert uut('*', '01.web.example.com') == True
    assert uut('*.example.com', '01.web.example.com') == True
    assert uut('01.*.example.com', '01.web.example.com') == True
    assert uut('*.example.com', '02.web.foobar.com') == False


def test_read_with_permission():
    with mock.patch.object(module, '_load_config') as load_config_mock:
        load_config_mock.return_value = {
            'zones': [{
                'zone': 'example.com',
                'certificates': [{
                    'hostname': 'example.com',
                    'available-to': '*.web.example.com',
                }],
            }],
        }
        with mock.patch('__builtin__.open') as open_mock:
            open_mock().__enter__().read.return_value = 'foo'
            pillar = module.ext_pillar('1.web.example.com', {})

        assert pillar['acme-dns']['example.com']['ecdsa']['cert']
        assert pillar['acme-dns']['example.com']['ecdsa']['key']
        assert pillar['acme-dns']['example.com']['rsa']['cert']
        assert pillar['acme-dns']['example.com']['rsa']['key']


def test_read_without_permission():
    with mock.patch.object(module, '_load_config') as load_config_mock:
        load_config_mock.return_value = {
            'zones': [{
                'zone': 'example.com',
                'certificates': [{
                    'hostname': 'example.com',
                    'available-to': '*.web.example.com',
                }],
            }],
        }

        pillar = module.ext_pillar('other.com', {})

        assert pillar == {}


def test_read_access_list():
    with mock.patch.object(module, '_load_config') as load_config_mock:
        load_config_mock.return_value = {
            'zones': [{
                'zone': 'example.com',
                'certificates': [{
                    'hostname': 'example.com',
                    'available-to': [
                        '*.web.example.com',
                        '*.other.com',
                    ]
                }],
            }],
        }
        with mock.patch('__builtin__.open') as open_mock:
            open_mock().__enter__().read.return_value = 'foo'
            pillar = module.ext_pillar('foo.other.com', {})

        assert pillar['acme-dns']['example.com']['ecdsa']['cert']
        assert pillar['acme-dns']['example.com']['ecdsa']['key']
        assert pillar['acme-dns']['example.com']['rsa']['cert']
        assert pillar['acme-dns']['example.com']['rsa']['key']
