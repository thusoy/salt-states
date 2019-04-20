{% set spotifyd = pillar.get('spotifyd', {}) %}

include:
    - .pillar_check


spotifyd:
    pkg.installed:
        - name: unzip

    file.managed:
        - name: /usr/local/src/spotifyd.zip
        - source: https://github.com/Spotifyd/spotifyd/releases/download/v0.2.5/spotifyd-2019-02-25-amd64.zip
        - source_hash: sha256=11b1ea0363cd3e217bf2553bffa49380a834c8b4a5b8d4f5aee1fd434fdefdce

    cmd.watch:
        - name: unzip /usr/local/src/spotifyd.zip -d /usr/local/bin
        - require:
            - pkg: spotifyd
        - watch:
            - file: spotifyd

    init_script.managed:
        - systemd: salt://spotifyd/job-systemd

    service.running:
        - watch:
            - cmd: spotifyd
            - init_script: spotifyd
            - file: spotifyd-config


spotifyd-config:
    file.managed:
        - name: /etc/spotifyd.conf
        - source: salt://spotifyd/spotifyd.conf
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - show_changes: False
