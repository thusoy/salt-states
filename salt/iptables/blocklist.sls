{% set iptables = pillar.get('iptables', {}) %}
{% set blocklist = iptables.get('blocklist', []) %}

iptables-blocklist:
    firewall.chain_present:
        - name: blocklist
        - table: filter
        - family: ipv4


iptables-blocklist-jump:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: ipv4
        - match:
            - comment
        - comment: "iptables.blocklist: Match against manually configured blocks"
        - jump: blocklist
        - order: 2
        - require:
            - firewall: iptables-blocklist


iptables-blocklist-return:
    firewall.append:
        - chain: blocklist
        - table: filter
        - family: ipv4
        - order: last
        - jump: RETURN


{% for blocked_ip in blocklist %}
iptables-blocklist-{{ blocked_ip }}:
    firewall.append:
        - chain: blocklist
        - family: ipv4
        - table: filter
        - source: {{ blocked_ip }}
        - match:
            - comment
        - comment: "iptables.blocklist: Manual block on {{ blocked_ip }}"
        - target: DROP
        - require:
            - firewall: iptables-blocklist
{% endfor %}
