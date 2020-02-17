#!py

def run():
    '''Sanity-checks the vault pillar values.'''
    vault = __pillar__.get('vault', {})
    dev_mode = vault.get('dev')

    if not dev_mode:
        assert 'tls_cert' in vault, 'Must specify pillar vault:tls_cert'
        assert 'tls_key' in vault, 'Must speicfy pillar vault:tls_key'

    # Verify that we can reliably autodetect the api_addr if unset
    if not 'api_addr' in vault:
        ip4_interfaces = __grains__.get('ip4_interfaces', {})
        nonlocal_interfaces = [key for key in ip4_interfaces if key != 'lo']
        # Only has one interface
        assert len(nonlocal_interfaces) == 1
        # That interface only has one address
        assert len(ip4_interfaces[nonlocal_interfaces[0]]) == 1

    return {}
