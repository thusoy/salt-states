{% set jumphost = pillar.get('jump-host', {}) %}

{% for target_name, target in jumphost.get('allow', {}).items() %}

jump-host-outbound-firewall-{{ target_name }}:
    firewall.append:
        - table: filter
        - family: ipv4
        - chain: OUTPUT
        - protocol: {{ target.get('protocol', 'tcp') }}
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
        - comment: 'jump-host: Allow outgoing traffic to {{ target_name }}'
        - jump: ACCEPT
{% endfor %}
