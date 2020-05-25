import contextlib
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta
try:
    from unittest import mock
except:
    import mock

import pytest

sys.path.insert(0, os.path.dirname(__file__))

from ssh_keys import ext_pillar as uut


def test_unconfigured():
    assert uut('foo', {}) == {}


def test_missing_root_key():
    assert uut('foo', {}, [{'path': 'foo', 'minion_globs': ['bar']}]) == {}


def test_creates_new_key(ssh_key, keystore):
    ret = uut('foo', {}, root_keys=[{
        'path': ssh_key,
    }], keystore=keystore)

    assert 'openssh_server' in ret
    assert 'host_ed25519_key' in ret['openssh_server']
    assert 'host_ed25519_certificate' in ret['openssh_server']
    key = ret['openssh_server']['host_ed25519_key']
    assert key.startswith(b'-----BEGIN OPENSSH PRIVATE KEY-----')
    cert = ret['openssh_server']['host_ed25519_certificate']
    assert cert.startswith(b'ssh-ed25519-cert-v01@openssh.com ')

    # Should have put the files on disk in a predictable location
    assert os.path.exists(keystore + '/' + 'foo-ed25519')
    cert_path = keystore + '/' + 'foo-ed25519-cert.pub'
    assert os.path.exists(cert_path)
    assert get_cert_principals(cert_path) == ['foo']


def test_creates_all_key_types(ssh_key, keystore):
    ret = uut('foo', {}, root_keys=[{
        'path': ssh_key,
    }], keystore=keystore, key_types=['rsa', 'ecdsa'])

    assert 'openssh_server' in ret
    assert 'host_ecdsa_key' in ret['openssh_server']
    assert 'host_rsa_key' in ret['openssh_server']


def test_reuses_existing_valid_cert(ssh_key, root_ssh_key, keystore):
    cert_path = sign_cert_with_validity(ssh_key, root_ssh_key, timedelta(days=2))
    with open(cert_path, 'rb') as fh:
        original_cert = fh.read()
    os.rename(cert_path, os.path.join(keystore, 'foo-ed25519-cert.pub'))
    os.rename(ssh_key, os.path.join(keystore, 'foo-ed25519'))

    ret = uut('foo', {}, root_keys=[{
        'path': root_ssh_key,
    }], keystore=keystore)

    assert 'openssh_server' in ret
    assert 'host_ed25519_key' in ret['openssh_server']
    assert 'host_ed25519_certificate' in ret['openssh_server']
    key = ret['openssh_server']['host_ed25519_key']
    assert key.startswith(b'-----BEGIN OPENSSH PRIVATE KEY-----')
    cert = ret['openssh_server']['host_ed25519_certificate']
    assert cert == original_cert


def test_recreates_cert_close_to_expiry(ssh_key, root_ssh_key, keystore):
    cert_path = sign_cert_with_validity(ssh_key, root_ssh_key, timedelta(minutes=1))
    with open(cert_path, 'rb') as fh:
        original_cert = fh.read()
    os.rename(cert_path, os.path.join(keystore, 'foo-ed25519-cert.pub'))
    os.rename(ssh_key, os.path.join(keystore, 'foo-ed25519'))

    ret = uut('foo', {}, root_keys=[{
        'path': root_ssh_key,
    }], keystore=keystore)

    assert 'openssh_server' in ret
    assert 'host_ed25519_key' in ret['openssh_server']
    assert 'host_ed25519_certificate' in ret['openssh_server']
    cert = ret['openssh_server']['host_ed25519_certificate']
    assert cert != original_cert


def test_deletes_expired_certs(ssh_key, root_ssh_key, keystore):
    cert_path = sign_cert_with_validity(ssh_key, root_ssh_key, timedelta(hours=-2))
    other_cert_path = os.path.join(keystore, 'other-ed25519-cert.pub')
    other_key_path = os.path.join(keystore, 'other-ed25519')
    os.rename(cert_path, other_cert_path)
    os.rename(ssh_key, other_key_path)

    ret = uut('foo', {}, root_keys=[{
        'path': root_ssh_key,
    }], keystore=keystore)

    assert 'openssh_server' in ret
    assert not os.path.exists(other_cert_path)
    assert not os.path.exists(other_key_path)


def test_sets_principals(ssh_key, keystore):
    grains = {
        'ip_interfaces': {
            'lo': ['127.0.0.1'],
            'eth0': ['1.2.3.4'],
        }
    }
    with mock.patch.dict(uut.__globals__, {'__grains__': grains}):
        ret = uut('foobar.example.com', {}, root_keys=[{
            'path': ssh_key,
        }], keystore=keystore, principals={
            '*': [
                '$minion_id',
            ],
            '*.example.com': [
                'example.com',
            ],
            'foobar.example.com': [
                '$ip',
            ],
        })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['1.2.3.4', 'example.com', 'foobar.example.com']


def test_sets_principal_from_string_grain(ssh_key, keystore):
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x, default='': 'foo',
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut('foobar.example.com', {}, root_keys=[{
            'path': ssh_key,
        }], keystore=keystore, principals={
            '*': [
                '$minion_id',
                '$grain:random_grain',
            ],
        })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['foo', 'foobar.example.com']


def test_sets_principal_from_list_grain(ssh_key, keystore):
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x, default='': ['foo', 'bar'],
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut('foobar.example.com', {}, root_keys=[{
            'path': ssh_key,
        }], keystore=keystore, principals={
            '*': [
                '$minion_id',
                '$grain:random_grain',
            ],
        })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['bar', 'foo', 'foobar.example.com']


def test_sets_principal_from_unknown_grain(ssh_key, keystore):
    mocked_salt_dunder = {
        '__salt__': {
            'grains.get': lambda x, default='': {'foo': 'bar'},
        },
    }
    with mock.patch.dict(uut.__globals__, mocked_salt_dunder):
        ret = uut('foobar.example.com', {}, root_keys=[{
            'path': ssh_key,
        }], keystore=keystore, principals={
            '*': [
                '$minion_id',
                '$grain:random_grain',
            ],
        })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['foobar.example.com']


def test_sets_principal_from_string_pillar(ssh_key, keystore):
    ret = uut('foobar.example.com', {'random_pillar': 'foo'}, root_keys=[{
        'path': ssh_key,
    }], keystore=keystore, principals={
        '*': [
            '$minion_id',
            '$pillar:random_pillar',
        ],
    })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['foo', 'foobar.example.com']


def test_ignores_empty_principal(ssh_key, keystore):
    ret = uut('foobar.example.com', {'random_pillar': ''}, root_keys=[{
        'path': ssh_key,
    }], keystore=keystore, principals={
        '*': [
            '$minion_id',
            '$pillar:random_pillar',
        ],
    })

    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == ['foobar.example.com']


def test_without_principals(ssh_key, keystore):
    ret = uut('foobar.example.com', {}, root_keys=[{
        'path': ssh_key,
    }], keystore=keystore, principals={
        '*': [],
    })

    assert 'openssh_server' in ret
    assert 'host_ed25519_key' in ret['openssh_server']
    assert 'host_ed25519_certificate' in ret['openssh_server']
    cert_path = keystore + '/' + 'foobar.example.com-ed25519-cert.pub'
    assert get_cert_principals(cert_path) == []


def test_preserves_hardcoded_keys(ssh_key, keystore):
    ret = uut('foobar.example.com', {'openssh_server': {'host_ed25519_key': b'foo'}},
        root_keys=[{
            'path': ssh_key,
        }],
        keystore=keystore,
    )

    assert ret['openssh_server'] == {}


def sign_cert_with_validity(key_path, root_key_path, validity):
    subprocess.check_call([
        'ssh-keygen',
        '-s', root_key_path,
        '-h',
        '-I', 'testidentifier',
        '-q',
        '-V', get_ssh_validity(
            datetime.utcnow() - timedelta(hours=3),
            datetime.utcnow() + validity,
        ),
        key_path,
    ])
    return key_path + '-cert.pub'


@pytest.yield_fixture
def keystore():
    keystore = tempfile.mkdtemp()
    try:
        yield keystore
    finally:
        shutil.rmtree(keystore)


def get_ssh_validity(start, end):
    ssh_time_format = '%Y%m%d%H%M%S'
    return '%s:%s' % (start.strftime(ssh_time_format), end.strftime(ssh_time_format))


def get_cert_principals(cert_path):
    output = subprocess.check_output([
        'ssh-keygen',
        '-L',
        '-f', cert_path,
    ]).decode('utf-8')
    return sorted(parse_principals_from_cert_details(output))


def parse_principals_from_cert_details(cert_text):
    '''
    >>> parse_principals_from_cert_details("""/var/lib/salt-ssh-keys/foobar.pub:
    ...         Type: ssh-ed25519-cert-v01@openssh.com host certificate
    ...         Public key: ED25519-CERT SHA256:pNCVPlhB2PHxyRYZJFnt3sayxIthTOroGaRIPks3Xdo
    ...         Signing CA: ED25519 SHA256:5QAn3wjKKwZdtC+3OOr29z9Zo7971SogOwPFGYjPFhg
    ...         Key ID: "foobar"
    ...         Serial: 0
    ...         Valid: from 2020-02-02T23:30:17 to 2020-02-05T23:30:17
    ...         Principals:
    ...                 1.2.3.45
    ...                 foobar
    ...         Critical Options: (none)
    ...         Extensions: (none)
    ... """)
    ['1.2.3.45', 'foobar']
    '''
    principals = []
    lines = cert_text.split('\n')
    for index, line in enumerate(lines):
        if line.strip() == 'Principals:':
            for potential_principal in lines[index + 1:]:
                if not potential_principal.startswith(' ' * 16):
                    break
                principals.append(potential_principal.strip())
    return principals


@pytest.yield_fixture
def ssh_key():
    for key in create_ssh_key():
        yield key


@pytest.yield_fixture
def root_ssh_key(ssh_key):
    # Simple alias of ssh_key to be able to use it twice for the same test
    for key in create_ssh_key():
        yield key


def create_ssh_key():
    cert = tempfile.NamedTemporaryFile()
    cert.close()
    subprocess.check_call([
        'ssh-keygen',
        '-t', 'ed25519',
        '-f', cert.name,
        '-N', '', # no passphrase
        '-q',
    ])

    try:
        yield cert.name
    finally:
        try:
            os.remove(cert.name)
        except OSError:
            pass
