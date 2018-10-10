#!py

def run():
    sasl2 = __pillar__.get('sasl2', {})

    keys = ['service', 'service_user', 'username', 'password']
    for key in keys:
        assert key in sasl2, 'sasl2 pillar must specify a "%s" key' % key

    return {}
