#!py

def run():
    '''Validate that the gcloud-backup pillar has the necessary config.'''
    gcloud_backup = __salt__['mdl_saltdata.resolve_leaf_values'](__pillar__.get('gcloud-backup', {}))
    destination = gcloud_backup.get('destination')
    assert destination, (
        'pillar gcloud-backup:destination required but missing')
    assert destination.endswith('/'), 'gcloud-backup:destination must end with a slashg'
    directories = gcloud_backup.get('directories')
    files = gcloud_backup.get('files')
    assert directories or files, (
        'pillar gcloud-backup:directories or gcloud-backup:files is required and must be non-empty')

    return {}
