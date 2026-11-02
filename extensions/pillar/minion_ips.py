'''
Load the IPs of the minions created by hart from its minion store
(/var/lib/hart/minions.json by default) into the saltmaster's pillar, for the
`salt-master.minion-firewall` state to only allow incoming connections from
those IPs.

Only the IPs a minion actually connects from are included: the private IPs for
minions with `connect_via_private_ip` set in the store, otherwise the public
IPs. Records without the field (imported before hart tracked it) get both.

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
import json
import logging

_logger = logging.getLogger(__name__)

DEFAULT_MINION_STORE_PATH = '/var/lib/hart/minions.json'


def ext_pillar(minion_id, pillar, master=None, minion_store_path=DEFAULT_MINION_STORE_PATH, **kwargs):
    if master is None:
        _logger.warning('The minion_ips extension has not been configured with '
            'a saltmaster, thus not returning anything')
        return {}

    if not fnmatch.fnmatch(minion_id, master):
        return {}

    try:
        with open(minion_store_path) as fh:
            store = json.load(fh)
    except (IOError, OSError, ValueError):
        _logger.exception('Errored while loading the minion store at %s', minion_store_path)
        return {}

    minions = {}
    for record_minion_id, record in store['minions'].items():
        ips = get_connecting_ips(record)
        if not ips:
            # An empty source would open the firewall to everyone
            _logger.warning('No IPs found for minion %s in the minion store, skipping',
                record_minion_id)
            continue
        minions[record_minion_id] = ips

    return {
        'salt_master': {
            'minions': minions,
        }
    }


def get_connecting_ips(record):
    connect_via_private_ip = record.get('connect_via_private_ip')
    if connect_via_private_ip is None:
        return record.get('public_ips', []) + record.get('private_ips', [])
    if connect_via_private_ip:
        return record.get('private_ips', [])
    return record.get('public_ips', [])
