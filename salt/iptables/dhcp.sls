iptables-dhcp-v4:
    firewall.append:
        - family: ipv4
        - chain: OUTPUT
        - protocol: udp
        - dport: 67
        - sport: 68
        - match:
            - comment
            - owner
        - uid-owner: root
        - comment: 'iptables.dhcp: Allow root outbound dhcp'
        - jump: ACCEPT


iptables-dhcp-v6:
    firewall.append:
        - family: ipv6
        - chain: OUTPUT
        - protocol: udp
        - dport: 547
        - sport: 546
        - match:
            - comment
            - owner
        - uid-owner: root
        - comment: 'iptables.dhcp: Allow root outbound dhcp'
        - jump: ACCEPT
