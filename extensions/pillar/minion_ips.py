'''
Loads the IPs of the minions created by hart from its minion store into the
saltmasters pillar, use the `salt-master.minion-firewall` state to only allow
incoming connections from those IPs. Minions created before the store existed
are read from a legacy file (<minion_id> <minion_ip> [<minion_ip>..]) until
they're backfilled with `hart import-minion`; the store wins if a minion is in
both.

Configure the extension with the master minion id (or a glob):

ext_pillar:
    - minion_ips:
        master: salt.example.com

The IPs will end up in pillar like this:

salt_master:
    minions:
        example-minion:
            - 1.2.3.4
'''

import fnmatch
import ipaddress
import json
import logging

_logger = logging.getLogger(__name__)


def ext_pillar(minion_id, pillar, master=None, minion_ip_path='/etc/salt/minion_ips',
        minion_store_path='/var/lib/hart/minions.json', **kwargs):
    if master is None:
        _logger.warning('The minion_ips extension has not been configured with '
            'a saltmaster, thus not returning anything')
        return {}

    if not fnmatch.fnmatch(minion_id, master):
        return {}

    minions = _read_legacy_file(minion_ip_path)
    minions.update(_read_minion_store(minion_store_path))

    return {
        'salt_master': {
            'minions': minions,
        }
    }


def _read_minion_store(path):
    try:
        with open(path) as fh:
            store = json.load(fh)
    except FileNotFoundError:
        return {}
    except:
        _logger.exception('Errored while reading the hart minion store at %s', path)
        return {}

    minions = {}
    for found_minion_id, record in store.get('minions', {}).items():
        # The firewall rules are only added for ipv4
        ips = [ip for ip in record.get('public_ips', []) + record.get('private_ips', [])
            if ipaddress.ip_address(ip).version == 4]
        if ips:
            minions[found_minion_id] = ips
    return minions


def _read_legacy_file(path):
    try:
        fh = open(path)
    except FileNotFoundError:
        return {}
    except:
        _logger.exception('Errored while opening minion IP file at %s', path)
        return {}

    minions = {}
    with fh:
        for line in fh:
            found_minion_id, minion_ips = line.strip().split(None, 1)
            minions[found_minion_id] = minion_ips.split()
    return minions
