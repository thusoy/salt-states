import os
import sys
try:
    from unittest import mock
except:
    import mock

sys.path.insert(0, os.path.dirname(__file__))

import mdl_saltdata


def test_pillar_resolver():
    uut = mdl_saltdata.resolve_leaf_values
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x: None,
            'pillar.get': lambda x: 'pillar value',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut({
            'regular_key': 'regular value',
            'key_pillar': 'pillar key',
        })
        assert ret == {
            'regular_key': 'regular value',
            'key': 'pillar value',
        }


def test_grain_resolver():
    uut = mdl_saltdata.resolve_leaf_values
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x: 'grain value',
            'pillar.get': lambda x: 'grain value',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut({
            'regular_key': 'regular value',
            'key_grain': 'grain key',
        })
        assert ret == {
            'regular_key': 'regular value',
            'key': 'grain value',
        }


def test_pillar_resolver_list():
    uut = mdl_saltdata.resolve_leaf_values
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x: None,
            'pillar.get': lambda x: 'pillar value',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut({
            'regular_key': 'regular value',
            'key_pillar': ['pillar key'],
        })
        assert ret == {
            'regular_key': 'regular value',
            'key': ['pillar value'],
        }


def test_pillar_resolver_recursive():
    uut = mdl_saltdata.resolve_leaf_values
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x: None,
            'pillar.get': lambda x: 'pillar value',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut({
            'outer': {
                'inner': {
                    'value_pillar': 'pillar key'
                }
            },
        })
        assert ret == {
            'outer': {
                'inner': {
                    'value': 'pillar value',
                }
            }
        }


def test_pillar_resolver_recursive_list():
    uut = mdl_saltdata.resolve_leaf_values
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x: None,
            'pillar.get': lambda x: 'pillar value',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut({
            'outer': [
                {
                    'value_pillar': 'pillar key'
                }
            ],
            'non-dict-list': ['foo'],
        })
        assert ret == {
            'outer': [
                {
                    'value': 'pillar value',
                }
            ],
            'non-dict-list': ['foo'],
        }
