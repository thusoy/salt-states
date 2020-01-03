import contextlib
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timedelta

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
    assert key.startswith('-----BEGIN OPENSSH PRIVATE KEY-----')
    cert = ret['openssh_server']['host_ed25519_certificate']
    assert cert.startswith('ssh-ed25519-cert-v01@openssh.com ')

    # Should have put the files on disk in a predictable location
    assert os.path.exists(keystore + '/' + 'foo-ed25519')
    assert os.path.exists(keystore + '/' + 'foo-ed25519-cert.pub')


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
    assert key.startswith('-----BEGIN OPENSSH PRIVATE KEY-----')
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


def sign_cert_with_validity(key_path, root_key_path, validity):
    subprocess.check_call([
        'ssh-keygen',
        '-s', root_key_path,
        '-h',
        '-I', 'testidentifier',
        '-q',
        '-V', get_ssh_validity(datetime.utcnow() - timedelta(minutes=2), datetime.utcnow() + validity),
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
