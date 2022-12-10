{% set duplicity = pillar.get('duplicity', {}) %}
{% set tempdir = duplicity.get('tempdir') %}

include:
    - .
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


{% if tempdir %}
duplicity-tempdir:
    file.directory:
        - name: {{ tempdir }}
        - makedirs: True
{% endif %}


{% for backupname, values in duplicity.get('targets', {}).items() %}
duplicity-backup-{{ backupname }}:
    file.managed:
        - name: /etc/duplicity/{{ backupname }}.sh
        - source: salt://duplicity/scripts/backup.sh
        - template: jinja
        - show_changes: False
        - context:
            backupname: {{ backupname }}
            tempdir: {{ tempdir if tempdir else '~' }}
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
