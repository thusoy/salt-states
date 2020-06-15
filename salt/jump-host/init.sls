{% set jumphost = pillar.get('jump-host', {}) %}

{% for target in jumphost.get('allow', []) %}

jump-host-outbound-firewall-{{ target.name }}:
    firewall.append:
        - table: filter
        - family: ipv4
        - chain: OUTPUT
        - proto: tcp
        {% if 'dport' in target %}
        - dport: {{ target.dport }}
        {% elif 'dports' in target %}
        - dports: {{ target.dports }}
        {% endif %}
        {% if 'destination' in target %}
        - destination: {{ target.destination }}
        {% endif %}
        - match:
            - comment
        - comment: 'jump-host: Allow outgoing traffic to {{ target.name }}'
        - jump: ACCEPT
{% endfor %}
