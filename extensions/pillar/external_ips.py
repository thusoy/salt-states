'''
Helper to provide external ip for providers that don't expose this directly to
the minion, like GCE and AWS. This is similar to minion_ips, but exposes the IP
to the minion owning it.

The IPs are read from hart's minion store, falling back to the legacy minion_ips
file for minions created before the store existed.
'''

import ipaddress
import json


def ext_pillar(minion_id, pillar, minion_ips_path='/etc/salt/minion_ips',
        minion_store_path='/var/lib/hart/minions.json', **kwargs):
    all_ips = _read_minion_store(minion_store_path, minion_id)
    if all_ips is None:
        all_ips = _read_legacy_file(minion_ips_path, minion_id)
    if all_ips is None:
        return {}

    return {
        'external_ips': [ip for ip in all_ips if ipaddress.ip_address(ip).is_global],
    }


def _read_minion_store(path, minion_id):
    try:
        with open(path) as fh:
            store = json.load(fh)
    except:
        return None

    record = store.get('minions', {}).get(minion_id)
    if record is None:
        return None
    return record.get('public_ips', []) + record.get('private_ips', [])


def _read_legacy_file(path, minion_id):
    try:
        fh = open(path)
    except:
        return None

    with fh:
        for line in fh:
            found_minion_id, minion_ip = line.strip().split(None, 1)
            if found_minion_id == minion_id:
                return minion_ip.split()

    return None
