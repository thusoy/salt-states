#!py

import base64

def run():
    """Sanity check that the nginx pillar value contains required values. """
    nginx_pillar = __pillar__.get('nginx', {})

    # Check that the default TLS cert and key is present (necessary to properly reject
    # invalid subdomain requests)
    assert 'default_cert' in nginx_pillar, 'Default TLS certificate for nginx not specified'
    assert 'default_key' in nginx_pillar, 'Default TLS key for nginx not specified'

    # Check that if S3 dumping of logs is requested a target bucket is specified
    if nginx_pillar.get('dump_to_s3'):
        assert 's3_bucket' in nginx_pillar, ('dumping logs to S3 requires a bucket to'
            ' be specified')

    for session_key in nginx_pillar.get('ssl_session_tickets', []):
        decoded = base64.b64decode(session_key)
        assert len(decoded) in (48, 80), ('Each ssl_session_ticket length must '
            'be 48 or 80 bytes decoded')
