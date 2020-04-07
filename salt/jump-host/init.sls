{% set jumphost = pillar.get('jump-host', {}) %}

{% for target in jumphost.get('allow', []) %}

jump-host-outbound-firewall-{{ target.name }}:
    firewall.append:
        - table: filter
        - family: ipv4
        - chain: OUTPUT
        - proto: tcp
        - dport: {{ target.dport }}
        {% if 'destination' in target %}
        - destination: {{ target.destination }}
        {% endif %}
        - match:
            - comment
            - owner
        - comment: 'jump-host: Allow outgoing traffic to {{ target.name }}'
        - jump: ACCEPT
{% endfor %}
