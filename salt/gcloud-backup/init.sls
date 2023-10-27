include:
    - .pillar_check
    - cronic


gcloud-backup:
    file.managed:
        - name: /usr/bin/gcloud-backup.sh
        - source: salt://gcloud-backup/script.sh
        - template: jinja
        - mode: 750
        - user: root
        - group: root

    cron.present:
        - name: cronic /usr/bin/gcloud-backup.sh
        - identifier: gcloud-backup
        - minute: random
        - hour: 0
