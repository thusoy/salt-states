# gcloud-backup

Adds a backup script that runs daily backups of configured directories to a GCS bucket. If you want encryption (like CSEK), configure that in your boto config by adding an `encryption_key` (and/or `decryption_key`) value with the key there.

This script runs gsutil with the `-d` flag on directories, meaning files in the destination that do not exist in the source will be deleted. For this to be usable for backups, make sure the bucket is specified with versioning, and optionally a lifecycle rule to delete non-current objects after whatever threshold you find reasonable. Files will only be overridden on changes.

Sample pillar:

```yaml
gcloud-backup:
    destination: gs://<bucket-name>
    directories:
        - /foo/bar
        - /bar/foo
```
