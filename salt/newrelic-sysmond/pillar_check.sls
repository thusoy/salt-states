#!py

def run():
    """ Sanity check that the newrelic pillar value contains at least the license key. """
    newrelic_pillar = __pillar__.get('newrelic-sysmond', {})

    # Check that the license key exists and is 40 characeters, otherwise the
    # service will fail to start
    license_key = newrelic_pillar.get('license_key')
    assert license_key is not None and len(license_key) == 40, ('No valid newrelic '
        'license key found in pillar, aborting...')

    return {}
