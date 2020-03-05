{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
hart-firewall-allow-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "hart: Allow outgoing dns"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


hart-firewall-allow-outgoing-ssh-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dports: 22,443
        - match:
            - comment
            - owner
        - comment: "hart: Allow outgoing SSH and HTTPS"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
