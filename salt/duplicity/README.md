duplicity
============

Installs duplicity. Use `duplicity.cron` if you want to also add cron jobs to run backups.

Note that this opens up the firewall for outgoing dns and https for root by default, if you
use a non-https backend you can customize the outbound port to allow with `duplicity:target_port`.

Pillar example:

```yaml
duplicity:
    targets:
        some-backup-name:
            source_dir: /var/lib
            target: s3://s3.amazonaws.com/<some-bucket>/<some-prefix>
            options:
                - --full-if-older-than 1M
            passphrase: <your-pasphrase>
```


A IAM policy like the following is needed:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::<some-bucket>/<some-prefix>/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucket",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::<some-bucket>"
            ]
        }
    ]
}
```

If you want to use duplicity to prune old backups instead of using lifecycle rules you need to grant DeleteObject as well.
