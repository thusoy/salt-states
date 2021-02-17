{% for chain, action in [
    ('logndrop', 'DROP'),
    ('lognreject', 'REJECT'),
] %}
{% for family in ('ipv4', 'ipv6') %}
iptables-{{ chain }}-{{ family }}:
    firewall.chain_present:
        - name: {{ chain }}
        - family: {{ family }}


iptables-{{ chain }}-log-{{ family }}:
    firewall.append:
        - chain: {{ chain }}
        - family: {{ family }}
        - match:
            - comment
            - limit
        - comment: "iptables.logndrop: Log non-conformant traffic..."
        - limit: 10/min
        - log-prefix: 'iptables.{{ chain }}: '
        - jump: LOG


iptables-{{ chain }}-drop-{{ family }}:
    firewall.append:
        - chain: {{ chain }}
        - family: {{ family }}
        - match:
            - comment
        - comment: "iptables.logndrop: ...And {{ action|lower }} it"
        - jump: {{ action }}
        - require:
            - firewall: iptables-{{ chain }}-log-{{ family }}
{% endfor %}
{% endfor %}
