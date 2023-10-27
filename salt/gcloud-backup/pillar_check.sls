#!py

def run():
    '''Validate that the gcloud-backup pillar has the necessary config.'''
    gcloud_backup = __salt__['mdl_saltdata.resolve_leaf_values'](__pillar__.get('gcloud-backup', {}))
    assert 'destination' in gcloud_backup, (
        'pillar gcloud-backup:destination required but missing')
    directories = gcloud_backup.get('directories')
    files = gcloud_backup.get('files')
    assert directories or files, (
        'pillar gcloud-backup:directories or gcloud-backup:files is required and must be non-empty')

    return {}
