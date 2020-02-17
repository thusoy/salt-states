#!py

import ipaddress


def run():
    '''Sanity-checks the vault pillar values.'''
    vault = __pillar__.get('vault', {})
    dev_mode = vault.get('dev')

    if not dev_mode:
        assert 'tls_cert' in vault, 'Must specify pillar vault:tls_cert'
        assert 'tls_key' in vault, 'Must speicfy pillar vault:tls_key'

    # Verify that we can reliably autodetect the api_addr if unset
    if not 'api_addr' in vault.get('config', {}):
        # ip4_interfaces seems buggy as lots of interfaces don't show up there
        # when fetched from here, thus using ip_interfaces and filtering manually
        ip_interfaces = __grains__.get('ip_interfaces', {})
        nonlocal_interfaces = [key for key in ip_interfaces if key != 'lo']
        # Only has one interface
        assert len(nonlocal_interfaces) == 1, ("Couldn't autodetect vault api "
            'address from interfaces, specify vault:config:api_addr in pillar (found %s)' %
            ','.join(nonlocal_interfaces))
        # That interface only has one address
        all_addresses = ip_interfaces[nonlocal_interfaces[0]]
        ipv4_addresses = [a for a in all_addresses if ipaddress.ip_address(a).version == 4]
        assert len(ipv4_addresses) == 1, (
            "Couldn't autodetect vault api address from addresses, specify "
            'vault:config:api_addr in pillar. (found %s)' % ','.join(ipv4_addresses))

    auth = vault.get('auth', {})
    required_properties = ('environment_variable_name', 'filename', 'secret')
    for auth_name, auth_properties in auth.items():
        for required_property in required_properties:
            assert required_property in auth_properties, ('pillar vault:auth:%s must '
                'specify the %s key' % (auth_name, required_property))

    return {}
