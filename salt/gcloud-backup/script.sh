{% set gcloud_backup = salt['mdl_saltdata.resolve_leaf_values'](pillar.get('gcloud-backup', {})) -%}

#!/bin/sh

set -eu

# Using gcloud storage would be the "modern" approach, but since this doesn't
# currently seem to work with --quiet we stay on gsutil for now.

# Force destination to end with a slash
raw_destination="{{ gcloud_backup.get('destination') }}"
destination="${raw_destination%/}/"
{% if gcloud_backup.get('exclude') -%}
exclude="-x {{ gcloud_backup.exclude }}"
{% else -%}
exclude=""
{%- endif %}

{% for directory in gcloud_backup.get('directories') %}
gsutil \
    --quiet \
    -m \
    rsync -r -d -P $exclude "{{ directory }}" "${destination}{{ directory[1:] }}"
{% endfor -%}

{% for file in gcloud_backup.get('files') %}
{# For individual file backups we can't use the rsync command directly since it -#}
{# only operates on directories. We also don't want to just call cp every time, since -#}
{# that would overwrite the file for every run, regardless of whether there's actually -#}
{# been any changes. Grab the md5 of the current file and compare to the local to decide -#}
{# whether to upload. -#}
current_hash=$(md5sum "{{ file }}" \
    | cut -d ' ' -f1 \
    | python3 -c 'import base64, sys; print(base64.b64encode(bytes.fromhex(sys.stdin.read())).decode("utf-8"))'
)
cloud_hash=$(gsutil ls -L "${destination}{{ file[1:] }}" \
    | grep 'Hash (md5)' \
    | cut -d: -f2 \
    | tr -d ' '
)
if [ "$current_hash" != "$cloud_hash" ]; then
    gsutil \
        --quiet \
        -m \
        cp -P "{{ file }}" "${destination}{{ file[1:] }}"
fi
{% endfor -%}
