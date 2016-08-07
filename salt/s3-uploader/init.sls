{% set s3_uploader = pillar.get('s3-uploader', {}) %}

include:
    - .pillar_check

# Just use a custom bash script instead of awscli to get away with less dependencies and
# being able to have easier IAM policies, I couldn't get a simple PutObject policy to work
# with `awscli s3 cp`.
s3-uploader:
    file.managed:
        - name: /usr/bin/s3-uploader
        - source: salt://s3-uploader/s3-uploader.sh
        - template: jinja
        - user: root
        - group: root
        - mode: 700
        - show_changes: False
        - context:
            key: {{ s3_uploader.access_key_id }}
            secret: {{ s3_uploader.secret_access_key }}
