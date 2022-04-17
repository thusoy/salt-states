laim-repo-key:
    file.managed:
        - name: /usr/share/keyrings/thusoy-archive-keyring.gpg
        - source: salt://laim/release-key.gpg


laim-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/thusoy-laim.list
        # Restrict repo key to only be usable with the laim repo
        - contents: deb [signed-by=/usr/share/keyrings/thusoy-archive-keyring.gpg] https://repo.thusoy.com/apt/debian {{ grains.oscodename }} main
        - require:
            - file: laim-repo-key

# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
laim-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/thusoy-laim.pref
        - contents: |
            Package: *
            Pin: origin repo.thusoy.com
            Pin-Priority: 1

            Package: laim
            Pin: origin repo.thusoy.com
            Pin-Priority: 500

    cmd.watch:
        - name: apt-get update -y
        - watch:
            - file: laim-repo
            - file: laim-repo-key
            - file: laim-repo-preferences


laim:
    pkg.installed:
        - require:
            - file: laim-repo

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
