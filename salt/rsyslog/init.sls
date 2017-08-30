rsyslog:
    pkg.installed: []

    file.managed:
        - name: /etc/rsyslog.conf
        - source: salt://rsyslog/rsyslog.conf
        - template: jinja

    service.running:
        - watch:
            - file: rsyslog
