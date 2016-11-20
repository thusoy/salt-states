#!py

def run():
    poff = __pillar__.get('poff', {})

    assert 'secret_key' in poff, 'poff pillar must have "secret_key"'
    assert 'db_password' in poff, 'poff pillar must have "db_password"'

    return {}
