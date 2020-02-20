ntp:
    pkg:
        - installed

    file.managed:
        - name: /etc/ntp.conf
        - source: salt://ntp/ntp.conf
        - template: jinja

    service.running:
        - require:
            - pkg: ntp
        - watch:
            - file: ntp


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
ntp-firewall-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'ntp: Allow outbound DNS'
        - uid-owner: ntp
        - jump: ACCEPT
        - require:
            - pkg: ntp
{% endfor %}

ntp-firewall-outgoing-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: udp
        - sport: 123
        - dport: 123
        - match:
            - comment
            - owner
        - comment: "ntp: Allow outgoing NTP queries"
        - uid-owner: ntp
        - jump: ACCEPT
        - require:
            - pkg: ntp
{% endfor %}
