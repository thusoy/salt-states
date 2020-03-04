#!py

def run():
    """
    Sanity-checks the salt-master pillar values.
    """
    salt_master = __pillar__.get('salt_master', {})

    for required_key in ('master_config', 'master_minion_config'):
        assert required_key in salt_master, ('Missing required pillar config '
            'salt_master:%s' % required_key)

    return {}
