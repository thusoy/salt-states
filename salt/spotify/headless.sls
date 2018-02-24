{% set spotify = pillar.get('spotify', {}) %}
{% set user = spotify.get('user', 'root') %}


include:
    - .


spotify-headless:
    pkg.installed:
        - name: xvfb

    init_script.managed:
        - name: spotify
        - systemd: salt://spotify/headless-systemd
        - template: jinja
        - context:
            user: {{ user }}

    service.running:
        - name: spotify
        - enable: True
        - require:
            - pkg: spotify-headless
        - watch:
            - init_script: spotify-headless
