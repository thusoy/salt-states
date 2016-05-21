# Never run this state without also configuring ssh rules to prevent being locked out
include:
    - ssh
    - .blocklist
    - .icmp
    - .logndrop
    - .sanity-check


iptables-deps:
    pkg.installed:
        - pkgs:
            - iptables-persistent


iptables-rules:
    firewall.apply:
        - order: last


{% for family in ('ipv4', 'ipv6') %}
iptables-log-nonmatched-input-{{ family }}:
    firewall.append:
        - table: filter
        - family: {{ family }}
        - chain: INPUT
        - jump: LOG
        - match:
            - comment
            - limit
        - comment: "iptables: Log all non-matching packets"
        - limit: 10/min
        - log-prefix: 'iptables.default: '
        - order: last
        - require_in:
            - firewall: iptables-rules


# Allow all traffic on local interface
iptables-allow-incoming-on-lo-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - if: lo
        - jump: ACCEPT
        - match: comment
        - order: 2
        - comment: "iptables: Allow traffic to lo"


iptables-allow-incoming-established-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - match:
            - comment
            - conntrack
        - ctstate: ESTABLISHED,RELATED
        - comment: "iptables: Allow incoming established traffic"
        - order: 2
        - jump: ACCEPT


iptables-output-allow-to-local-{{ family }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - match:
            - comment
        - comment: "iptables: Allow traffic to lo"
        - out-interface: lo
        - order: 2
        - jump: ACCEPT


# Needed for many things, salt to fetch files, apt to find repos, etc
{% for protocol in ('udp', 'tcp') %}
iptables-allow-outgoing-dns-for-root-{{ family }}-{{ protocol }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - proto: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "iptables: Allow outgoing DNS for root"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


iptables-output-allow-established-{{ family }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - match:
            - comment
            - conntrack
        - comment: "iptables: Allow established outgoing"
        # RELATED allows FIN-ACKs for closed sockets
        - ctstate: ESTABLISHED,RELATED
        - order: 2
        - jump: ACCEPT


iptables-output-log-unmatched-{{ family }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - match:
            - comment
            - limit
        - comment: "iptables: Log non-matched outgoing packets"
        - log-prefix: "iptables.outgoing-unmatched: "
        - limit: 10/min
        - log-uid: ''
        - jump: LOG
        - order: last
        - require_in:
            - firewall: iptables-rules


{% endfor %} # end ipv4/ipv6


# Split iptables related logs to /var/log/iptables.log
iptables-rsyslog-config:
    file.managed:
        - name: /etc/rsyslog.d/11-iptables.conf
        - source: salt://iptables/iptables-rsyslog.conf

    service.running:
        - name: rsyslog
        - watch:
            - file: iptables-rsyslog-config


# Rotate the logs
iptables-logrotate-config:
    file.managed:
        - name: /etc/logrotate.d/iptables
        - contents: |
            /var/log/iptables.log {
                daily
                missingok
                rotate 14
                compress
                notifempty
            }
