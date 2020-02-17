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
        assert len(nonlocal_interfaces) == 1, ("Couldn't autodetect vault api "
            'address from interfaces, specify vault:config:api_addr in pillar (found %s)' %
            ','.join(nonlocal_interfaces))
        # That interface only has one address
        addresses = ip4_interfaces[nonlocal_interfaces[0]]
        assert len(addresses) == 1, (
            "Couldn't autodetect vault api address from addresses, specify "
            'vault:config:api_addr in pillar. (found %s)' % ','.join(addresses))

    return {}
