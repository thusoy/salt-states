{% set rkt = pillar.get('rkt', {}) %}
{% set version_spec = rkt.get('version_spec', '1.30.0 sha256=57e1d8ec5075369a0781d1c3aac2dcc032d73f4c2b292bcb61a52a53cd02d301') %}
{% set version, version_hash = version_spec.split(' ') %}


rkt:
    file.managed:
        - name: /usr/local/src/rkt.deb
        - source:  https://github.com/rkt/rkt/releases/download/v{{ version }}/rkt_{{ version }}-1_amd64.deb
        - source_hash: {{ version_hash }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/rkt.deb
        - watch:
            - file: rkt
