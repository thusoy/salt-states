# Helper module to configure for Papertrail.

include:
    - rsyslog
    - .pillar_check


rsyslog-papertrail-ca-certs:
    file.managed:
        - name: /etc/papertrail-ca-certs.pem
        - source: salt://rsyslog/papertrail/ca-certs.pem
        - watch_in:
            - service: rsyslog


rsyslog-papertrail:
    pkg.installed:
        - name: rsyslog-gnutls

    file.managed:
        - name: /etc/rsyslog.d/90-papertrail.conf
        - source: salt://rsyslog/papertrail/papertrail.conf
        - template: jinja
        - context:
            papertrail_rule: "{{ salt['pillar.get']('rsyslog:papertrail') }}"
        - watch_in:
            - service: rsyslog
