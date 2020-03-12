{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
terraform-firewall-allow-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "terraform: Allow outgoing dns"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


terraform-firewall-allow-outgoing-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: "terraform: Allow outgoing HTTPS"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
