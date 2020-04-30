openttd:
    pkg.installed


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
openttd-firewall-inbound-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: {{ protocol }}
        - dport: 3979
        - match:
            - comment
        - comment: 'openttd: Allow inbound'
        - jump: ACCEPT
{% endfor %}
{% endfor %}
