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
    files:
        - /some/file
```

POSIX attributes on files are preserved, but not on directories, thus if any directories backed up need to be restored with the same owner and mode you need to handle that separately.

You can define a regex of files to exclude (that will apply to all directories):

```yaml
gcloud-backup:
    destination: gs://<bucket-name>
    directories:
        - /foo
    exclude: '\.sock$' # To f. ex ignore sockets
```

Restoration is a matter of running `gsutil -m rsync -r -P gs://<bucket> <destination-dir>`. You might want to restore to a non-root directory initially to review and fix directory permissions before copying over to root (ie with regular `rsync`).
