import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))

from minion_ips import ext_pillar as uut


def build_minion_store():
    store = tempfile.NamedTemporaryFile()
    store.write(json.dumps({
        'version': 1,
        'minions': {
            'public-minion': {
                'minion_id': 'public-minion',
                'public_ips': ['5.6.7.8'],
                'private_ips': ['10.10.10.10'],
                'connect_via_private_ip': False,
            },
            'internal-minion': {
                'minion_id': 'internal-minion',
                'public_ips': ['9.10.11.12'],
                'private_ips': ['10.20.30.40'],
                'connect_via_private_ip': True,
            },
            'no-public-ip-minion': {
                'minion_id': 'no-public-ip-minion',
                'public_ips': [],
                'private_ips': ['10.50.60.70'],
                'connect_via_private_ip': True,
            },
        },
    }).encode('utf-8'))
    store.flush()
    return store


def test_returns_the_ips_each_minion_connects_from():
    store = build_minion_store()

    ret = uut('salt.example.com', {},
        master='salt.example.com',
        minion_store_path=store.name)

    assert ret == {
        'salt_master': {
            'minions': {
                'public-minion': ['5.6.7.8'],
                'internal-minion': ['10.20.30.40'],
                'no-public-ip-minion': ['10.50.60.70'],
            },
        },
    }


def test_record_without_connectivity_field_falls_back_to_available_ips():
    # Records imported before the connect_via_private_ip field existed
    store = tempfile.NamedTemporaryFile()
    store.write(json.dumps({
        'version': 1,
        'minions': {
            'old-private-only-minion': {
                'minion_id': 'old-private-only-minion',
                'public_ips': [],
                'private_ips': ['10.20.30.40'],
            },
        },
    }).encode('utf-8'))
    store.flush()

    ret = uut('salt.example.com', {},
        master='salt.example.com',
        minion_store_path=store.name)

    assert ret == {
        'salt_master': {
            'minions': {
                'old-private-only-minion': ['10.20.30.40'],
            },
        },
    }


def test_only_returns_data_for_the_master():
    store = build_minion_store()

    ret = uut('other-minion.example.com', {},
        master='salt.example.com',
        minion_store_path=store.name)

    assert ret == {}


def test_missing_store_returns_nothing():
    ret = uut('salt.example.com', {},
        master='salt.example.com',
        minion_store_path='/nonexistent')

    assert ret == {}


def test_skips_minions_without_any_connecting_ip():
    # An empty source in the firewall state would allow everyone
    store = tempfile.NamedTemporaryFile()
    store.write(json.dumps({
        'version': 1,
        'minions': {
            'ipless-minion': {
                'minion_id': 'ipless-minion',
                'public_ips': ['1.2.3.4'],
                'private_ips': [],
                'connect_via_private_ip': True,
            },
            'minion': {
                'minion_id': 'minion',
                'public_ips': ['5.6.7.8'],
                'private_ips': [],
                'connect_via_private_ip': False,
            },
        },
    }).encode('utf-8'))
    store.flush()

    ret = uut('salt.example.com', {},
        master='salt.example.com',
        minion_store_path=store.name)

    assert ret == {
        'salt_master': {
            'minions': {
                'minion': ['5.6.7.8'],
            },
        },
    }
