#!py

def run():
    '''Sanity-checks the vault pillar values.'''
    vault = __pillar__.get('vault', {})
    dev_mode = vault.get('dev')

    if not dev_mode:
        assert 'tls_cert' in vault, 'Must specify pillar vault:tls_cert'
        assert 'tls_key' in vault, 'Must speicfy pillar vault:tls_key'

    return {}
