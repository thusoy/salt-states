{% from 'duplicity/map.jinja' import duplicity with context %}

include:
    - duplicity
    - cronic


duplicity-s3-deps:
    pkg.installed:
        - name: python{{ '3' if grains['osmajorrelease']|int > 10 else '' }}-boto


duplicity-job-directory:
    file.directory:
        - name: /etc/duplicity
        - user: root
        - group: root
        - mode: 750


{% for backupname, values in duplicity.get('targets', {}).items() %}
duplicity-backup-{{ backupname }}:
    file.managed:
        - name: /etc/duplicity/{{ backupname }}.sh
        - source: salt://duplicity/scripts/backup.sh
        - template: jinja
        - show_changes: False
        - context:
            backupname: {{ backupname }}
            tempdir: {{ duplicity.tempdir }}
        - user: root
        - group: root
        - mode: 750
        - require:
            - file: duplicity-job-directory

    cron.present:
        - name: cronic /etc/duplicity/{{ backupname }}.sh
        - identifier: duplicity-backup-{{ backupname }}
        - minute: random
        - hour: 3

{% endfor %}
