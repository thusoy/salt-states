'''
Assuming that you have a process to create minions where you can extract its
IPs and put them in a file (<minion_id> <minion_ip> [<minion_ip>..]), use this
extension to load them into the saltmasters pillar and use the
`salt-master.minion-firewall` state to only allow incoming connections from
those IPs.

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
import logging

_logger = logging.getLogger(__name__)


def ext_pillar(minion_id, pillar, master=None, minion_ip_path='/etc/salt/minion_ips', **kwargs):
    if master is None:
        _logger.warning('The minion_ips extension has not been configured with '
            'a saltmaster, thus not returning anything')
        return {}

    if not fnmatch.fnmatch(minion_id, master):
        return {}

    try:
        fh = open(minion_ip_path)
    except:
        _logger.exception('Errored while opening minion IP file at %s', minion_ip_path)
        return {}

    minions = {}
    with fh:
        for line in fh:
            minion_id, minion_ips = line.strip().split(None, 1)
            minions[minion_id] = minion_ips.split()

    return {
        'salt_master': {
            'minions': minions,
        }
    }
