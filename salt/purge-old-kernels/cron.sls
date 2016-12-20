{% set cron_day_spec = salt['pillar.get']('purge-old-kernels:cron_day_spec', '*/7') %}
{% set kernels_to_keep = salt['pillar.get']('purge-old-kernels:kernels_to_keep', 2) %}

include:
    - purge-old-kernels
    - cronic


purge-old-kernels-cron:
    cron.present:
        - name: cronic /usr/local/bin/purge-old-kernels -y --keep {{ kernels_to_keep }}
        - identifier: purge-old-kernels-regularly
        - daymonth: '{{ cron_day_spec }}'
        - minute: random
        - hour: random

