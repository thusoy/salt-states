#!py

def run():
    acme_dns = __pillar__.get('acme-dns', {})
    toplevel_required_keys = (
        'account-key',
        'contact',
    )
    for key in toplevel_required_keys:
        assert key in acme_dns, ('acme_dns pillar does not specify required '
            'key "%s"' % key)

    for zone in acme_dns.get('zones', []):
        required_zone_keys = (
            'certificates',
            'key-algorithm',
            'key-name',
            'key-secret',
            'update-server',
        )
        for key in required_zone_keys:
            assert key in zone, 'acme-dns pillar zone does not define key "%s"' % key

        for certificate in zone['certificates']:
            required_certificate_keys = (
                'available-to',
                'hostname',
            )
            for key in required_certificate_keys:
                assert key in certificate, ('acme-dns pillar does not define'
                    'required key "%s" in zone for %s' % (key, zone['update-server']))

    return {}
