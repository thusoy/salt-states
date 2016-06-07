{% for family in ('ipv4', 'ipv6') %}
iptables-incoming-icmp-chain-{{ family }}:
    firewall.chain_present:
        - name: incoming-icmp
        - family: {{ family }}


iptables-outgoing-icmp-chain-{{ family }}:
    firewall.chain_present:
        - name: outgoing-icmp
        - family: {{ family }}


iptables-incoming-icmp-chain-last-rule-{{ family }}:
    firewall.append:
        - chain: incoming-icmp
        - family: {{ family }}
        - match:
            - comment
        - comment: 'iptables.icmp: Reject the rest'
        - jump: REJECT
        - order: last
        - require_in:
            - firewall: iptables-rules


iptables-outgoing-icmp-chain-last-rule-{{ family }}:
    firewall.append:
        - chain: outgoing-icmp
        - family: {{ family }}
        - match:
            - comment
        - comment: 'iptables.icmp: Reject the rest'
        - jump: REJECT
        - order: last
        - require_in:
            - firewall: iptables-rules


iptables-incoming-icmp-jump-{{ family }}:
    firewall.append:
        - chain: INPUT
        - family: {{ family }}
        - match:
            - comment
        - comment: 'iptables.icmp: Allow a subset of icmp'
        - proto: {{ 'icmp' if family == 'ipv4' else 'icmpv6' }}
        - jump: incoming-icmp
        - order: 2


iptables-outgoing-icmp-jump-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - match:
            - comment
        - comment: 'iptables.icmp: Allow a subset of icmpv6'
        - proto: {{ 'icmp' if family == 'ipv4' else 'icmpv6' }}
        - jump: outgoing-icmp
        - order: 2
{% endfor %}


# Allow a subset of icmp messages from all hosts
{% for icmp_msg_num, icmp_msg_text in {
        '0': 'echo-reply',
        '3/1': 'destination-unreachable/host-unreachable',
        '3/3': 'destination-unreachable/port-unreachable',
        '3/4': 'destination-unreachable/fragmentation-needed',
        '8': 'echo-request',
        '11': 'time-exceeded',
    }.items() %}
iptables-allow-incoming-icmp-{{ icmp_msg_text }}:
    firewall.append:
        - table: filter
        - chain: incoming-icmp
        - family: ipv4
        - match:
            - icmp
            - comment
            - limit
        - protocol: icmp
        - icmp-type: {{ icmp_msg_num }}
        - comment: "iptables: Allow incoming {{ icmp_msg_text }}"
        - limit: 90/min
        - jump: ACCEPT
{% endfor %} # end icmp msgs


# Allow a subset of outgoing icmp messages
{% for icmp_msg_num, icmp_msg_text in {
        '0': 'echo-reply',
        '3/1': 'destination-unreachable/host-unreachable',
        '3/3': 'destination-unreachable/port-unreachable',
        '3/4': 'destination-unreachable/fragmentation-needed',
        '8': 'echo-request',
        '11': 'time-exceeded',
    }.items() %}
iptables-allow-outgoing-icmp-{{ icmp_msg_text }}:
    firewall.append:
        - table: filter
        - chain: outgoing-icmp
        - family: ipv4
        - match:
            - icmp
            - comment
        - protocol: icmp
        - icmp-type: {{ icmp_msg_num }}
        - comment: "iptables: Allow outgoing {{ icmp_msg_text }}"
        - jump: ACCEPT
{% endfor %} # end icmp msgs


# Allow a subset of icmpv6 messages, as minimum recommended by RFC 4890
# Ref. http://www.ietf.org/rfc/rfc4890.txt
{% for icmp_msg_num, icmp_msg_text in {
        '1': 'destination-unreachable',
        '2': 'packet-too-big',
        '3/0': 'time-exceeded/hop-limit-exceeded',
        '3/1': 'time-exceeded/fragment-reassembly-time-exceeded',
        '4/1': 'parameter-problem/unrecognized-next-header',
        '4/2': 'parameter-problem/unrecognized-ipv6-option',
        '128': 'echo-request',
        '129': 'echo-response',
    }.items() %}
iptables-allow-incoming-icmpv6-{{ icmp_msg_text }}:
    firewall.append:
        - table: filter
        - chain: incoming-icmp
        - family: ipv6
        - match:
            - icmpv6
            - comment
            - limit
        - comment: "iptables: Allow incoming {{ icmp_msg_text }}"
        - protocol: icmpv6
        - limit: 90/min
        - icmpv6-type: {{ icmp_msg_num }}
        - jump: ACCEPT
{% endfor %} # end icmpv6 msgs


# Allow another subset of icmpv6 messages from the closest router only
{% for icmp_msg_num, icmp_msg_text in {
        '134/0': 'router-advertisement',
        '135/0': 'neighbour-solicitation',
        '136/0': 'neighbour-advertisement',
    }.items() %}
iptables-allow-incoming-icmpv6-{{ icmp_msg_text }}:
    firewall.append:
        - table: filter
        - chain: incoming-icmp
        - family: ipv6
        - source: fe80::/10
        - destination: fe80::/10
        - match:
            - icmpv6
            - comment
            - limit
            - hl
        - comment: "iptables: Allow incoming {{ icmp_msg_text }}"
        - hl-eq: 255 # Hop limit for these should always be 255, i.e. should not have passed through a router
        - protocol: icmpv6
        - limit: 90/min
        - icmpv6-type: {{ icmp_msg_num }}
        - jump: ACCEPT
{% endfor %} # end icmp msgs


# Allow a subset of outgoing icmpv6
{% for icmp_msg_num, icmp_msg_text in {
    '1': 'destination-unreachable',
    '2': 'packet-too-big',
    '3/0': 'time-exceeded/hop-limit-exceeded',
    '3/1': 'time-exceeded/fragment-reassembly-time-exceeded',
    '4/1': 'parameter-problem/unrecognized-next-header',
    '4/2': 'parameter-problem/unrecognized-ipv6-option',
    '128': 'echo-request',
    '129': 'echo-response',
    '133/0': 'router-solicitation',
    '135/0': 'neighbour-solicitation',
    '136/0': 'neighbour-advertisement',
    }.items() %}
iptables-allow-outgoing-icmpv6-{{ icmp_msg_text }}:
    firewall.append:
        - family: ipv6
        - chain: outgoing-icmp
        - table: filter
        - match:
            - comment
            - icmpv6
        - comment: "iptables: Allow outgoing ICMPv6 {{ icmp_msg_text }}"
        - proto: icmpv6
        - icmpv6-type: {{ icmp_msg_num }}
        - jump: ACCEPT
{% endfor %}
