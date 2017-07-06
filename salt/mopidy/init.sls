{% set mopidy = pillar.get('mopidy', {}) %}

include:
    - .pillar_check


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
        - user: mopidy
        - group: root
        - mode: 440
        - show_changes: False
        - require:
            - pkg: mopidy

    service.running:
        - enable: True
        - watch:
            - file: mopidy

    firewall.append:
        - chain: INPUT
        - proto: tcp
        - dport: 6600
        - match:
            - comment
        - comment: "mopidy: Allow MPD"
        - jump: ACCEPT


{% if 'local' in mopidy %}
mopidy-local-media-dir:
    file.directory:
        - name: {{ mopidy.local.media_dir }}
        - user: mopidy
{% endif %}
