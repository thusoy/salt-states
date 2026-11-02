'''
Helper to provide the external IPs for providers that don't expose this
directly to the minion, like GCE and AWS. This is similar to minion_ips, but
exposes the IPs to the minion owning them, read from hart's minion store
(/var/lib/hart/minions.json by default).
'''

import json
import logging

_logger = logging.getLogger(__name__)

DEFAULT_MINION_STORE_PATH = '/var/lib/hart/minions.json'


def ext_pillar(minion_id, pillar, minion_store_path=DEFAULT_MINION_STORE_PATH, **kwargs):
    try:
        with open(minion_store_path) as fh:
            store = json.load(fh)
    except (IOError, OSError, ValueError):
        _logger.exception('Errored while loading the minion store at %s', minion_store_path)
        return {}

    record = store['minions'].get(minion_id)
    if record is None:
        return {}

    return {
        'external_ips': record.get('public_ips', []),
    }
