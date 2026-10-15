import json
import os
import sys
import tempfile
import textwrap
try:
    from unittest import mock
except:
    import mock

import pytest

sys.path.insert(0, os.path.dirname(__file__))

from external_ips import ext_pillar as uut


def test_external_ips():
    minion_ips = tempfile.NamedTemporaryFile()
    minion_ips.write(textwrap.dedent('''\
        other-minion 2.3.4.5
        test-minion 1.2.3.4 10.10.10.10
    ''').encode('utf-8'))
    minion_ips.flush()

    ret = uut('test-minion', {}, minion_ips_path=minion_ips.name,
        minion_store_path='/nonexistent')

    expected = ['1.2.3.4'] if sys.version_info > (3, 0, 0) else ['1.2.3.4', '10.10.10.10']

    assert ret == {
        'external_ips': expected,
    }


def test_external_ips_from_minion_store():
    minion_store = write_minion_store({
        'test-minion': {'public_ips': ['1.2.3.4'], 'private_ips': ['10.10.10.10']},
    })

    ret = uut('test-minion', {},
        minion_ips_path='/nonexistent',
        minion_store_path=minion_store.name)

    assert ret == {
        'external_ips': ['1.2.3.4'],
    }


def test_external_ips_store_wins_over_legacy_file():
    minion_ips = tempfile.NamedTemporaryFile()
    minion_ips.write(b'test-minion 2.3.4.5\n')
    minion_ips.flush()
    minion_store = write_minion_store({
        'test-minion': {'public_ips': ['1.2.3.4'], 'private_ips': []},
    })

    ret = uut('test-minion', {},
        minion_ips_path=minion_ips.name,
        minion_store_path=minion_store.name)

    assert ret == {
        'external_ips': ['1.2.3.4'],
    }


def test_external_ips_unknown_minion():
    minion_store = write_minion_store({})

    ret = uut('test-minion', {},
        minion_ips_path='/nonexistent',
        minion_store_path=minion_store.name)

    assert ret == {}


def write_minion_store(minions):
    minion_store = tempfile.NamedTemporaryFile()
    minion_store.write(json.dumps({'version': 1, 'minions': minions}).encode('utf-8'))
    minion_store.flush()
    return minion_store
