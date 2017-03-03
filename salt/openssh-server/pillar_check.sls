#!py

def run():
    openssh_server = __pillar__.get('openssh_server', {})

    accepted_key_types = (
        'ed25519',
        'rsa',
        'ecdsa',
    )
    assert any('host_%s_key' % key in openssh_server for key in accepted_key_types)

    return {}
