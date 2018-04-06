#!py

def run():
    """ Sanity-checks the opendkim pillar values. All domains need at least one key,
    and each key needs to have a private part.
    """
    required_keys = (
        'nvm:target_directory',
        'nvm:user',
    )
    for required_key in required_keys:
        value = __salt__['pillar.get'](required_key)
        assert value, '%s must be specified in pillar' % required_key
    return {}
