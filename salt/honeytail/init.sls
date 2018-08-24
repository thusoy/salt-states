{% set honeytail = pillar.get('honeytail', {}) %}
{% set version_info = '1.666 sha256=5ef58c165dcc1bfcb8df5438ff0df199e59064fb41960555f0406912d5bb2666' %}
{% set version, checksum = version_info.split() %}

honeytail-deb:
    file.managed:
        - name: /usr/local/src/honeytail-{{ version }}.deb
        - source: https://honeycomb.io/download/honeytail/linux/honeytail_{{ version }}_amd64.deb
        - source_hash: {{ checksum }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/honeytail-{{ version }}.deb
        - watch:
            - file: honeytail


honeytail:
    file.managed:
        - name: /etc/honeytail/honeytail.conf
        - source: salt://honeytail/honeytail.conf
        - template: jinja
        - require:
            - cmd: honeytail-deb

    service.running:
        - watch:
            - cmd: honeytail-deb
            - file: honeytail
