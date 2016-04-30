#!py

def run():
    """ Sanity check the mopidy pillar to ensure that all required fields
    are present.
    """
    mopidy = __pillar__.get('mopidy', {})
    if not mopidy:
        # no config is valid
        return {}

    validate_spotify(mopidy)
    validate_local(mopidy)

    return {}


def validate_spotify(mopidy):
    if 'spotify' in mopidy:
        assert 'username' in mopidy['spotify']
        assert 'password' in mopidy['spotify']


def validate_local(mopidy):
    if 'local' in mopidy:
        assert 'media_dir' in mopidy['local']
