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
{% set papertrail_ip_ranges = [
    '67.214.208.0/20',
    '173.247.96.0/19',
    '169.46.82.160/27',
] %}
rsyslog-papertrail-outbound-firewall:
    firewall.append:
        - family: ipv4
        - chain: OUTPUT
        - protocol: tcp
        - dport: {{ papertrail_destination.rsplit(':')[1] }}
        - destination: {{ ','.join(papertrail_ip_ranges) }}
        - match:
            - comment
        - comment: 'rsyslog.papertrail: Allow traffic to papertrail'
        - jump: ACCEPT


# TODO: This is currently unnecessary since rsyslog runs as root, but this
# should be dropped to an unprivileged user
# {% for family in ('ipv4', 'ipv6') %}
# {% for protocol in ('udp', 'tcp') %}
# rsyslog-papertrail-outbound-dns-{{ family }}-{{ protocol }}:
#     firewall.append:
#         - family: {{ family }}
#         - chain: OUTPUT
#         - protocol: {{ protocol }}
#         - dport: 53
#         - destination: system_dns
#         - match:
#             - comment
#             - owner
#         - comment: 'rsyslog.papertrail: Allow outgoing DNS for papertrail'
#         - uid-owner: rsyslog
#         - jump: ACCEPT
# {% endfor %}
# {% endfor %}
