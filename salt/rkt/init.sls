{% set rkt = pillar.get('rkt', {}) %}
{% set version_spec = rkt.get('version_spec', '1.30.0 sha256=57e1d8ec5075369a0781d1c3aac2dcc032d73f4c2b292bcb61a52a53cd02d301') %}
{% set version, version_hash = version_spec.split(' ') %}

rkt:
    file.managed:
        - name: /usr/local/src/rkt.deb
        - source: https://github.com/rkt/rkt/releases/download/v{{ version }}/rkt_{{ version }}-1_amd64.deb
        - source_hash: {{ version_hash }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/rkt.deb
        - watch:
            - file: rkt

    cron.present:
        # gc prints a lot of status messages that can't be silenced, ignore these
        # Ref https://github.com/rkt/rkt/issues/4005
        - identifier: rkt-gc
        - name: "rkt gc 2>&1
            | grep -v 'not removed: still within grace period'
            | grep -v 'Garbage collecting pod'
            | grep -v 'moving pod .* to garbage'
            | grep -v 'stage1 gc: error removing subcgroup .*: operation not permitted'"
        - hour: random
        - minute: random
