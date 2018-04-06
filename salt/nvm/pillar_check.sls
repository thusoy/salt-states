#!py

def run():
    """ Sanity-checks the opendkim pillar values. All domains need at least one key,
    and each key needs to have a private part.
    """
    target_directory = __salt__['pillar.get']('nvm:target_directory')
    assert target_directory, 'nvm:target_directory must be specified in pillar'
    return {}
