"""
Autogenerate certificate-based ssh keys for minions.

Keyword arguments comes from the saltmaster config where the module is
registered, use that to specify root keys and how to partition the certificates.
You probably want to have different certificates for each environment if you
have multiple environments on the same saltmaster, to prevent a compromised host
in one environment from being able to impersonate a host in another.

Installing and configuring the extension:

    $ sudo mkdir -p /var/lib/salt-ssh-keys
    $ sudo chown saltmaster:saltmaster /var/lib/salt-ssh-keys
    $ sudo chmod 750 /var/lib/salt-ssh-keys
    $ sudo -u saltmaster ssh-keygen -t ed25519 -N '' -f /var/lib/salt-ssh-keys/root

Add the output of the following to each client's ~/.ssh/known_hosts or
/etc/ssh/ssh_known_hosts to let them use the certificate to validate the
connection:

    $ echo "@cert-authority * $(sudo cat /var/lib/salt-ssh-keys/root.pub)"

Put this file in your saltmaster's `extension_modules` directory (or in one of
the `module_dirs`), and add the following to /etc/salt/master:

ext_pillar:
    - ssh_keys:
        root_keys:
            - path: /var/lib/salt-ssh-keys/root
              minion_globs:
                - "*"

Modify the root keys to your liking, eg by compartmentalizing by environment or
similar. The certificates will by default only have the minion id as a
principal. To enable logging in from another hostname, or an ip address, these
need to added as alternative principals. This can be specified in the module
configuration too, with a set of principals to add for a minion glob:

ext_pillar:
    - ssh_keys:
        root_keys:
            - path: /var/lib/salt-ssh-keys/root
              minion_globs:
                - "*"
        principals:
            '*.example.com':
                - example.com
                - $ip

This example shows how you can add both static principals ('example.com'), and
one of the dynamic ones ('$ip'). '$ip' will expand to all IPs found in the
grains for the minion. '$minion_id' will expand to the minion id. In addition
you can specify any grain key as '$grain:<key>', to include the grain with the
given key. For example, set '$grain:domain' to include the minion's domain.

This extension works in conjunction with the openssh-server state to provision
the keys to the servers.
"""

import fnmatch
import os
import re
import shutil
import subprocess
import tempfile
from datetime import datetime, timedelta
from logging import getLogger

_logger = getLogger(__name__)
VALID_RE = re.compile(r'Valid: .* ([0-9T:-]+)$')

try:
    basestring = basestring
except NameError:
    # python 3
    basestring = str


def ext_pillar(
        minion_id,
        pillar,
        root_keys=None,
        principals=None,
        validity_seconds=259200, # 3 days
        key_types=('ed25519',),
        keystore='/var/lib/salt-ssh-keys',
        **kwargs):
    if not root_keys:
        _logger.warning('The ssh_keys pillar extension is not configured '
            'with any root certificates')
        return {}

    root_key_path = get_root_key_path(minion_id, root_keys)
    if not root_key_path:
        _logger.warning('No root key for minion %s', minion_id)
        return {}

    validity = timedelta(seconds=validity_seconds)
    cert_principals = resolve_principals(minion_id, principals)
    ret = {}

    existing_ssh_pillar = pillar.get('openssh_server', {})
    for key_type in key_types:
        if 'host_%s_key' % key_type in existing_ssh_pillar:
            # Don't overwrite hardcoded keys
            continue

        key_path, cert_path = get_cert_for_minion(
            minion_id,
            root_key_path,
            key_type,
            keystore,
            validity,
            cert_principals,
        )

        with open(key_path, 'rb') as fh:
            ret['host_%s_key' % key_type] = fh.read()
        with open(cert_path, 'rb') as fh:
            ret['host_%s_certificate' % key_type] = fh.read()

    return {
        'openssh_server': ret,
    }


def get_cert_for_minion(minion_id, root_key_path, key_type, keystore, validity, principals):
    key_path = os.path.join(keystore, '%s-%s' % (minion_id, key_type))
    cert_path = os.path.join(keystore, '%s-%s-cert.pub' % (minion_id, key_type))
    existing_cert_expiry = get_cert_expiry(cert_path, minion_id)
    if existing_cert_expiry and existing_cert_expiry - datetime.utcnow() > validity/3:
        return key_path, cert_path

    # Re-create cert when less than a third of the lifetime left
    temp_key_path = generate_ssh_key(key_type)
    temp_cert_path = sign_ssh_key(temp_key_path, root_key_path, minion_id, validity,
        principals)
    shutil.move(temp_key_path, key_path)
    shutil.move(temp_cert_path, cert_path)

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


def sign_ssh_key(key_path, root_key_path, name, validity, principals):
    args = [
        'ssh-keygen',
        '-s', root_key_path,
        '-h',
        '-I', name,
        '-q',
        '-V', get_ssh_validity(validity),
    ]
    if principals:
        args.append('-n')
        args.append(','.join(principals))

    args.append(key_path)
    subprocess.check_call(args)

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
        ], stderr=subprocess.PIPE).decode('utf-8')
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


def resolve_principals(minion_id, principals):
    if not principals:
        # Include only minion_id when no explicit principals have been defined
        return [minion_id]

    collected_principal_sources = set()
    for minion_glob, principal_sources in principals.items():
        if fnmatch.fnmatch(minion_id, minion_glob):
            collected_principal_sources.update(principal_sources)

    ret = set()
    grain_prefix = '$grain:'
    pillar_prefix = '$pillar:'
    for principal_source in collected_principal_sources:
        if principal_source == '$minion_id':
            ret.add(minion_id)
        elif principal_source == '$ip':
            ret.update(get_nonlocal_ip_addresses())
        elif principal_source.startswith(grain_prefix):
            grain_key = principal_source[len(grain_prefix):]
            getter = __salt__['grains.get']
            add_flattened_value(ret, getter, grain_key, 'grain')
        elif principal_source.startswith(pillar_prefix):
            pillar_key = principal_source[len(pillar_prefix):]
            getter = __salt__['pillar.get']
            add_flattened_value(ret, getter, pillar_key, 'pillar')
        else:
            ret.add(principal_source)
    return ret


def get_nonlocal_ip_addresses():
    for interface, ip_addresses in __grains__.get('ip_interfaces', {}).items():
        if interface == 'lo':
            continue
        for ip in ip_addresses:
            yield ip


def add_flattened_value(dictionary, getter, key, kind):
    value = getter(key, default=None)
    if not value:
        _logger.warning('Ignoring principal from %s with key %r, was %r', kind, key, value)
    elif isinstance(value, (list, tuple)):
        dictionary.update(value)
    elif isinstance(value, basestring):
        dictionary.add(value)
    else:
        _logger.warning('Unknown value of %s %r, was %r. Ignoring.',
            kind, key, type(value))
