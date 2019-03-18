import fnmatch
import glob
import logging
import os
from collections import defaultdict

import yaml


_logger = logging.getLogger(__name__)


def ext_pillar(minion_id, pillar):
    config = _load_config()

    available_hostnames = []
    for zone in config['zones']:
        for certificate in zone['certificates']:
            minion_access = certificate['available-to']
            if not minion_access:
                available_hostnames.append(certificate['hostname'])
                continue

            if not isinstance(minion_access, list):
                minion_access = [minion_access]

            for pattern in minion_access:
                if _has_access(pattern, minion_id):
                    available_hostnames.append(certificate['hostname'])
                    break

    if not available_hostnames:
        return {}

    certs = defaultdict(dict)

    for hostname in available_hostnames:
        for key_type in ('ecdsa', 'rsa'):
            cert_path = '/var/lib/acme-dns/%s.%s.crt' % (hostname, key_type)
            key_path = '/var/lib/acme-dns/%s.%s.pem' % (hostname, key_type)
            try:
                with open(cert_path) as fh:
                    cert = fh.read()
                with open(key_path) as fh:
                    key = fh.read()
                certs[hostname][key_type] = {
                    'cert': cert,
                    'key': key,
                }
            except OSError as e:
                _logger.warning('Failed to load acme cert or key for %s. Error: %s',
                    hostname, e)

    return {
        'acme-dns': certs,
    }


def _load_config():
    with open('/etc/acme-dns.yaml') as fh:
        return yaml.safe_load(fh)


def _has_access(access_spec, minion_id):
    return fnmatch.fnmatchcase(minion_id, access_spec)
