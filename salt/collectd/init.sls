collectd:
    pkg.installed: []

    file.managed:
        - name: /etc/collectd/collectd.conf
        - source: salt://collectd/collectd.conf
        - template: jinja
        - require:
            - pkg: collectd

    service.running:
        - watch:
            - file: collectd
