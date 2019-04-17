{% set haveged = pillar.get('haveged', {}) %}
{% set low_entropy_watermark = haveged.get('low_entropy_watermark', 1024) %}

haveged:
    pkg.installed: []

    file.managed:
        - name: /etc/default/haveged
        - source: salt://haveged/defaults
        - template: jinja
        - context:
            low_entropy_watermark: {{ low_entropy_watermark }}

    service.running:
        - name: haveged
        - watch:
            - file: haveged

