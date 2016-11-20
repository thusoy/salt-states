#!py

def run():
    powerdns = __pillar__.get('powerdns', {})

    assert 'db_password' in powerdns, 'powerdns pillar must specify db_password'

    return {}
