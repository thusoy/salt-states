#!py

def run():
    postgres = __pillar__.get('postgres', {})

    if not postgres.get('internal', True) and not postgres.get('external_nossl', False):
        assert 'key' in postgres, 'postgres pillar must specify "key" when "internal"  is False'
        assert 'cert' in postgres, 'postgres pillar must specify "cert" when "internal"  is False'

    if postgres.get('cert_auth'):
        assert 'ca_file' in postgres, 'postgres pillar must specify "ca_file" when using cert_auth'
        assert 'crl_file' in postgres, ('postgres pillar must specify "crl_file" when '
            'using cert_auth')

    return {}
