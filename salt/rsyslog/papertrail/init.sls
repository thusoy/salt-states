# Helper module to configure for Papertrail.

include:
    - rsyslog
    - .pillar_check


{% set papertrail_destination = salt['pillar.get']('rsyslog:papertrail') %}

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
            papertrail_rule: "{{ papertrail_destination }}"
        - watch_in:
            - service: rsyslog


# From https://help.papertrailapp.com/kb/configuration/troubleshooting-remote-syslog-reachability/#sending-over-tcp
{% for ip_range in [
    '67.214.208.0/20',
    '173.247.96.0/19',
    '169.46.82.160/27',
] %}
rsyslog-papertrail-outbound-firewall-{{ ip_range }}:
    firewall.append:
        - family: ipv4
        - chain: OUTPUT
        - protocol: tcp
        - dport: {{ papertrail_destination.rsplit(':')[1] }}
        - destination: {{ ip_range }}
        - match:
            - comment
        - comment: 'rsyslog.papertrail: Allow traffic to papertrail'
        - jump: ACCEPT
{% endfor %}
