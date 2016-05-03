#!py

def run():
    """ Sanity check the activiti pillar to ensure that all required fields
    are present.
    """
    activiti = __pillar__.get('activiti', {})
    assert activiti is not None, "No activiti configuration found in pillar"
    mandatory_keys = (
        'db_password',
        'admin_password',
        'rest_password',
    )
    for key in mandatory_keys:
        assert key in activiti, ('Activiti pillar is missing mandatory '
            'configuration value \'%s\'' % key)
    return {}
