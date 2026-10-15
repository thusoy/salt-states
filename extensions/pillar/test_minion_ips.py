import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))

from minion_ips import ext_pillar as uut


def test_minion_ips_merges_store_and_legacy_file():
    minion_ips = tempfile.NamedTemporaryFile()
    minion_ips.write(b'old-minion 2.3.4.5 10.0.0.2\nmoved-minion 3.4.5.6\n')
    minion_ips.flush()
    minion_store = write_minion_store({
        'new-minion': {'public_ips': ['1.2.3.4'], 'private_ips': ['10.0.0.1']},
        'moved-minion': {'public_ips': ['4.5.6.7'], 'private_ips': []},
    })

    ret = uut('master.example.com', {}, master='master.*',
        minion_ip_path=minion_ips.name,
        minion_store_path=minion_store.name)

    assert ret == {
        'salt_master': {
            'minions': {
                'old-minion': ['2.3.4.5', '10.0.0.2'],
                'new-minion': ['1.2.3.4', '10.0.0.1'],
                'moved-minion': ['4.5.6.7'],
            },
        },
    }


def test_minion_ips_skips_ipv6_and_minions_without_ips():
    minion_store = write_minion_store({
        'dual-stack': {'public_ips': ['1.2.3.4', '2001:db8::1'], 'private_ips': []},
        'no-ips': {'public_ips': [], 'private_ips': []},
    })

    ret = uut('master.example.com', {}, master='master.*',
        minion_ip_path='/nonexistent',
        minion_store_path=minion_store.name)

    assert ret == {
        'salt_master': {
            'minions': {
                'dual-stack': ['1.2.3.4'],
            },
        },
    }


def test_minion_ips_only_for_master():
    ret = uut('other.example.com', {}, master='master.*',
        minion_ip_path='/nonexistent',
        minion_store_path='/nonexistent')

    assert ret == {}


def write_minion_store(minions):
    minion_store = tempfile.NamedTemporaryFile()
    minion_store.write(json.dumps({'version': 1, 'minions': minions}).encode('utf-8'))
    minion_store.flush()
    return minion_store
