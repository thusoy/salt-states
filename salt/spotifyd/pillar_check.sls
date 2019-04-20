#!py

def run():
    """ Sanity-checks the spotifyd pillar values.
    """
    spotifyd = __pillar__.get('spotifyd', {})

    assert 'username' in spotifyd, 'Must specify pillar spotifyd:username'
    assert 'password' in spotifyd, 'Must specify pillar spotifyd:password'

    return {}
