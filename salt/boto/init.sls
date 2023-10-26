{% set boto = pillar.get('boto') %}

boto:
    file.managed:
        - name: /root/.boto
        - source: salt://boto/config
        - user: root
        - group: root
        - mode: 640
        - show_changes: False
        - template: jinja
