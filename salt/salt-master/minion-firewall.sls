include:
    - iptables


{% for family in ('ipv4', 'ipv6') %}
salt-master-minion-firewall-chain-{{ family }}:
    firewall.chain_present:
        - name: salt-minions
        - family: {{ family }}


salt-master-minion-firewall-chain-{{ family }}-reject:
    firewall.append:
        - chain: salt-minions
        - family: {{ family }}
        - jump: REJECT
        - order: last
        - require:
            - firewall: salt-master-minion-firewall-chain-{{ family }}
        - require_in:
            - firewall: iptables-rules


salt-master-minion-firewall-jump-chain-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - proto: tcp
        - dports: 4505,4506
        - match: comment
        - comment: "salt-master.minion-firewall: Enable minion in/out"
        - jump: salt-minions
{% endfor %}


{% for minion, minion_ips in salt['pillar.get']('salt_master:minions', {}).items() %}
salt-master-minion-firewall-allow-{{ minion }}:
    firewall.append:
        - family: ipv4
        - chain: salt-minions
        - source: {{ ','.join(minion_ips) }}
        - match:
            - comment
        - comment: 'salt-master: Allow {{ minion }}'
        - jump: ACCEPT
{% endfor %}
