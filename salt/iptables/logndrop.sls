{% for family in ('ipv4', 'ipv6') %}
iptables-logndrop-chain-{{ family }}:
    firewall.chain_present:
        - name: logndrop
        - family: {{ family }}


iptables-logndrop-log-{{ family }}:
    firewall.append:
        - chain: logndrop
        - family: {{ family }}
        - match:
            - comment
        - comment: "iptables.logndrop: Log non-conformant traffic..."
        - jump: LOG


iptables-logndrop-drop-{{ family }}:
    firewall.append:
        - chain: logndrop
        - family: {{ family }}
        - match:
            - comment
        - comment: "iptables.logndrop: ...And drop it"
        - jump: DROP
        - require:
            - firewall: iptables-logndrop-log-{{ family }}
{% endfor %}
