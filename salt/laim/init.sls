laim:
    pkgrepo.managed:
        - name: deb https://repo.thusoy.com/apt/debian {{ grains.oscodename }} main
        - key_url: salt://laim/release-key.asc

    pkg.installed:
        - require:
            - pkgrepo: laim

    file.managed:
        - name: /etc/laim/config.yml
        - source: salt://laim/config.yml
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - show_changes: False
        - require:
            - pkg: laim

    service.running:
        - watch:
            - file: laim
