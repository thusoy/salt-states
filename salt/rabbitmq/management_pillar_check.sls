#!py

def run():
    '''Checks that passwords are set'''
    rabbitmq = __pillar__.get('rabbitmq', {})

    required_keys = (
        'admin_password',
        'monitoring_password',
        'management_tls_cert',
        'management_tls_key',
    )
    for required_key in required_keys:
        assert required_key in rabbitmq, 'rabbitmq:%s must be set' % required_key

    return {}
