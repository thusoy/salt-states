{% set poff = pillar.get('poff', {}) %}

include:
    - .pillar_check
    - pip
    - postgres.client
    - powerdns
    - virtualenv


poff-deps:
    pkg.installed:
        - pkgs:
            - python-dev
        - require:
            - pip: virtualenv


poff:
    user.present:
        - name: poff
        - fullname: Poff daemon
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin

    virtualenv.managed:
        - name: /srv/poff/venv
        - require:
            - pkg: poff-deps

    pip.installed:
        - name: poff[postgres]
        - bin_env: /srv/poff/venv
        - upgrade: True
        - require:
            - pkg: postgresql-client
            - pkg: poff-deps
            - virtualenv: poff

    cmd.wait:
        - name: POFF_CONFIG_FILE=/etc/poff.rc /srv/poff/venv/bin/poff init
        - watch:
            - pip: poff

    file.managed:
        - name: /etc/poff.rc
        - source: salt://poff/poff_config
        - user: root
        - group: poff
        - mode: 640
        - template: jinja
        - show_changes: False
        - require:
            - user: poff

    init_script.managed:
        - systemd: salt://poff/poff-systemd
        - upstart: salt://poff/poff-upstart

    service.running:
        - enable: True
        - require:
            - file: poff_log_dir
        - watch:
            - file: poff
            - init_script: poff
            - file: poff_log_config
            - pip: poff

    postgres_user.present:
        - name: poff
        - password: {{ poff.get('db_password') }}


{% for table in (
    'comments',
    'comments_id_seq',
    'cryptokeys',
    'cryptokeys_id_seq',
    'domainmetadata',
    'domainmetadata_id_seq',
    'domains',
    'domains_id_seq',
    'records',
    'records_id_seq',
    'supermasters',
    'tsigkeys',
    'tsigkeys_id_seq',
) %}
poff-database-privilege-{{ table }}:
    postgres_privileges.present:
        - name: poff
        - object_name: {{ table }}
        - object_type: {{ 'sequence' if table.endswith('_seq') else 'table' }}
        - maintenance_db: powerdns
        - privileges:
            - ALL
        - require:
            - postgres_user: poff
            - postgres_database: powerdns
{% endfor %}


poff_log_dir:
    file.directory:
        - name: /var/log/poff
        - user: root
        - group: poff
        - mode: 775
        - require:
            - user: poff


poff_log_config:
    file.managed:
        - name: /etc/poff_log_conf.yml
        - source: salt://poff/log_conf.yml
