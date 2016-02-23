#!py

def run():
    """ Sanity check that the awscli pillar value contains (probably) valid
    key IDs and secrets.
    """
    awscli_pillar = __pillar__.get('s3-uploader', {})
    assert 'secret_access_key' in awscli_pillar
    assert 'access_key_id' in awscli_pillar
