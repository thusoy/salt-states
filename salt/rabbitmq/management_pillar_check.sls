#!py

def run():
    '''Checks that passwords are set'''
    rabbitmq = __pillar__.get('rabbitmq', {})

    required_keys = [
        'admin_password',
        'monitoring_password',
    ]

    for required_key in required_keys:
        assert required_key in rabbitmq, 'rabbitmq:%s must be set' % required_key

    if rabbitmq.get('management_plaintext', False):
        tls_required_keys = [
            'management_tls_cert',
            'management_tls_key',
        ]
        for key in tls_required_keys:
            assert key in rabbitmq, ('rabbitmq:%s must be set, or '
                'rabbitmq:management_plaintext set to True' % key)

    return {}
