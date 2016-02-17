{% for family in ('ipv4', 'ipv6') %}
iptables-sanity-check-{{ family }}:
    firewall.chain_present:
        - name: sanity-check
        - family: {{ family }}


iptables-sanity-check-jump-{{ family }}:
    firewall.append:
        - chain: INPUT
        - family: {{ family }}
        - jump: sanity-check
        - order: 1


iptables-sanity-check-return-{{ family }}:
    firewall.append:
        - chain: sanity-check
        - family: {{ family }}
        - jump: RETURN
        - order: last
        - require_in:
            - firewall: iptables-rules
{% endfor %}


# Drop incoming traffic from private ranges (probably spoofed)
# Note that 10.0/8, 172.16/16 and 192.168/16 are allowed, otherwise private
# networking wouldn't work. These should be blocked on public interfaces
# though.
{% for source_range in (
    '224.0.0.0/4',
    '240.0.0.0/5',
    '127.0.0.0/8',
    ) %}
iptables-drop-incoming-private-traffic-{{ source_range }}:
    firewall.append:
        - chain: sanity-check
        - in-interface: "!lo"
        - match:
            - comment
        - comment: "iptables: Block spoofed addresses"
        - s: {{ source_range }}
        - jump: logndrop
{% endfor %} # end ipv4 spoofed ranges


{% for family in ('ipv4', 'ipv6') %}
# Block invalid packets
iptables-block-invalid-{{ family }}:
    firewall.append:
        - table: filter
        - chain: sanity-check
        - family: {{ family }}
        - match:
            - comment
            - conntrack
        - ctstate: INVALID
        - comment: "iptables: Drop invalid packets"
        - target: logndrop


# Block new connections without the SYN flag
# Ref https://www.frozentux.net/iptables-tutorial/chunkyhtml/x6249.html
iptables-block-new-without-syn-{{ family }}:
    firewall.append:
        - table: filter
        - chain: sanity-check
        - family: {{ family }}
        - proto: tcp
        - jump: logndrop
        - match:
            - state
            - comment
        - comment: "iptables: Block NEW connections without SYN flag"
        - connstate: NEW
        - syn: '!'
{% endfor %} # end family


# Block kernel from ever accepting a icmp redirect
iptables-block-kernel-redirect:
    sysctl.present:
        - name: net.ipv4.conf.all.accept_redirects
        - value: 0


# Block Smurf IP DoS attack
iptables-block-kernel-smurf:
    sysctl.present:
        - name: net.ipv4.icmp_echo_ignore_broadcasts
        - value: 1
