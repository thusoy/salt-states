mopidy:
    pkgrepo.managed:
        - name: deb http://apt.mopidy.com/ jessie main contrib non-free
        - key_url: salt://mopidy/release-key.asc

    pkg.installed:
         - pkgs:
            - mopidy
            - mopidy-spotify

    file.managed:
        - name: /etc/mopidy/mopidy.conf
        - source: salt://mopidy/mopidy.conf
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - show_diff: False

    firewall.append:
        - chain: INPUT
        - proto: tcp
        - port: 6600
        - match:
            - comment
        - comment: "mopidy: Allow MPD"
        - jump: ACCEPT
