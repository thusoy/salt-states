#!py

def run():
    """ Sanity-checks the pillar values. """
    certbot = pillar.get('certbot', {})

    assert 'administrative_contact' in certbot

    return {}
