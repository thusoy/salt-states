cachish-repo-key:
    file.managed:
        - name: /usr/share/keyrings/thusoy-archive-keyring.gpg
        - source: salt://cachish/release-key.gpg


cachish-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/thusoy-cachish.list
        # Restrict repo key to only be usable with the cachish repo
        - contents: deb [signed-by=/usr/share/keyrings/thusoy-archive-keyring.gpg] https://repo.thusoy.com/apt/debian {{ grains.oscodename }} main
        - require:
            - file: cachish-repo-key

# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
cachish-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/thusoy-cachish.pref
        - contents: |
            Package: *
            Pin: origin repo.thusoy.com
            Pin-Priority: 1

            Package: cachish
            Pin: origin repo.thusoy.com
            Pin-Priority: 500

    cmd.watch:
        # Update only the relevant repo to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/thusoy-cachish.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: cachish-repo
            - file: cachish-repo-key
            - file: cachish-repo-preferences

cachish:
    pkg.installed:
        - require:
            - cmd: cachish-repo-preferences

    file.managed:
        - name: /etc/cachish.yml
        - source: salt://cachish/config.yml
        - template: jinja
        - show_changes: False
        - user: root
        - group: cachish
        - mode: 640
        - require:
            - pkg: cachish

    service.running:
        - watch:
            - file: cachish


{% for family in ('ipv4', 'ipv6') %}
cachish-outgoing-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'cachish: Allow outgoing traffic'
        - uid-owner: cachish
        - jump: ACCEPT
        - require:
            - pkg: cachish


{% for protocol in ('tcp', 'udp') %}
cachish-outgoing-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'cachish: Allow outgoing DNS'
        - uid-owner: cachish
        - jump: ACCEPT
        - require:
            - pkg: cachish
{% endfor %}
{% endfor %}
