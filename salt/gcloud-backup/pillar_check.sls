#!py

def run():
    '''Validate that the gloud-backup pillar has the necessary config.'''
    gcloud_backup = __pillar__.get('gcloud-backup', {})
    destination = gcloud_backup.get('destination')
    assert destination, (
        'pillar gloud-backup:destination required but missing')
    assert destination.endswith('/'), 'gcloud-backup:destination must end with a slash'
    directories = gcloud_backup.get('directories')
    files = gcloud_backup.get('files')
    assert directories or files, (
        'pillar gloud-backup:directories or gcloud-backup:files is required and must be non-empty')

    return {}
