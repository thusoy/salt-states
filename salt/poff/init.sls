{% set poff = pillar.get('poff', {}) %}

include:
    - .pillar_check
    - postgres.client


poff-deps:
    pkg.installed:
        - pkgs:
            - python3-dev
            - python3-pip
            - python3-virtualenv


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
