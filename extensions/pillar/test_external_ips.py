import json
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))

from external_ips import ext_pillar as uut


def build_minion_store():
    store = tempfile.NamedTemporaryFile()
    store.write(json.dumps({
        'version': 1,
        'minions': {
            'other-minion': {
                'minion_id': 'other-minion',
                'public_ips': ['2.3.4.5'],
                'private_ips': [],
            },
            'test-minion': {
                'minion_id': 'test-minion',
                'public_ips': ['1.2.3.4'],
                'private_ips': ['10.10.10.10'],
            },
        },
    }).encode('utf-8'))
    store.flush()
    return store


def test_external_ips():
    store = build_minion_store()

    ret = uut('test-minion', {}, minion_store_path=store.name)

    assert ret == {
        'external_ips': ['1.2.3.4'],
    }


def test_minion_not_in_store_returns_nothing():
    store = build_minion_store()

    ret = uut('unknown-minion', {}, minion_store_path=store.name)

    assert ret == {}


def test_missing_store_returns_nothing():
    ret = uut('test-minion', {}, minion_store_path='/nonexistent')

    assert ret == {}
