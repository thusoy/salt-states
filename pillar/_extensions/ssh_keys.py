"""
Autogenerate certificate-based ssh keys for minions.

Keyword arguments comes from the saltmaster config where the module is
registered, use that to specify root keys and how to partition the certificates.
You probably want to have different certificates for each environment if you
have multiple environments on the same saltmaster, to prevent a compromised host
in one environment from being able to impersonate a host in another.

Create your root certificates, and tell the module where to find them and how
minions should be assigned to a cert:

- root_keys:
    - path: /path/to/cert
      minion_globs:
        - "*"

This extension works in conjunction with the openssh-server state to provision
the keys.
"""

import os
import re
import subprocess
import tempfile
import fnmatch
from datetime import datetime, timedelta
from logging import getLogger

_logger = getLogger(__name__)
VALID_RE = re.compile(r'Valid: .* ([0-9T:-]+)$')


def ext_pillar(
        minion_id,
        pillar,
        root_keys=None,
        validity=timedelta(days=3),
        key_types=('ed25519',),
        keystore='/var/lib/salt/ssh_keys',
        **kwargs):
    if not root_keys:
        _logger.warning('The ssh_keys pillar extension is not configured with any root certificates')
        return {}

    root_key_path = get_root_key_path(minion_id, root_keys)
    if not root_key_path:
        _logger.warning('No root key for minion %s', minion_id)
        return {}

    ret = {}

    for key_type in key_types:
        key_path, cert_path = get_cert_for_minion(
            minion_id,
            root_key_path,
            key_type,
            keystore,
            validity,
        )

        with open(key_path, 'rb') as fh:
            ret['host_%s_key' % key_type] = fh.read()
        with open(cert_path, 'rb') as fh:
            ret['host_%s_certificate' % key_type] = fh.read()

    return {
        'openssh_server': ret,
    }


def get_cert_for_minion(minion_id, root_key_path, key_type, keystore, validity):
    key_path = os.path.join(keystore, '%s-%s' % (minion_id, key_type))
    cert_path = os.path.join(keystore, '%s-%s-cert.pub' % (minion_id, key_type))
    existing_cert_expiry = get_cert_expiry(cert_path, minion_id)
    if existing_cert_expiry and existing_cert_expiry - datetime.utcnow() > validity/3:
        return key_path, cert_path

    # Re-create cert when less than a third of the lifetime left
    temp_key_path = generate_ssh_key(key_type)
    temp_cert_path = sign_ssh_key(temp_key_path, root_key_path, minion_id, validity)
    os.rename(temp_key_path, key_path)
    os.rename(temp_cert_path, cert_path)

    # Remove the unused pubkey
    os.remove(temp_key_path + '.pub')

    return key_path, cert_path


def get_root_key_path(minion_id, root_keys):
    for potential_key in root_keys:
        globs = potential_key.get('minion_globs')
        if not globs:
            return potential_key['path']

        for glob in globs:
            if fnmatch.fnmatch(minion_id, glob):
                return potential_key['path']

    _logger.warning('No root key found matching minion %s', minion_id)
    return None


def generate_ssh_key(key_type):
    key_path = tempfile.mktemp()
    subprocess.check_call([
        'ssh-keygen',
        '-t', key_type,
        '-f', key_path,
        '-N', '', # no passphrase
        '-q',
    ])
    return key_path


def sign_ssh_key(key_path, root_key_path, name, validity):
    subprocess.check_call([
        'ssh-keygen',
        '-s', root_key_path,
        '-h',
        '-I', name,
        '-q',
        '-V', get_ssh_validity(validity),
        key_path,
    ])

    # ssh-keygen doesn't enable specifying an output filename, but naming
    # follows a consistent template
    return key_path + '-cert.pub'


def get_ssh_validity(validity):
    now = datetime.utcnow()
    validity_end = now + validity
    ssh_time_format = '%Y%m%d%H%M%S'
    # The docs says it should be possible to only specify the end time, but
    # that fails for me
    return '%s:%s' % (now.strftime(ssh_time_format), validity_end.strftime(ssh_time_format))


def get_cert_expiry(cert_path, minion_id):
    try:
        output = subprocess.check_output([
            'ssh-keygen',
            '-L',
            '-f', cert_path,
        ], stderr=subprocess.PIPE)
    except Exception as e:
        return None

    for line in output.split('\n'):
        match = VALID_RE.search(line)
        if not match:
            continue

        formatted_time = match.group(1)
        return datetime.strptime(formatted_time, '%Y-%m-%dT%H:%M:%S')

    # TODO: Ignore and create a new one?
    raise ValueError('Unparseable certificate: %s' % output)

