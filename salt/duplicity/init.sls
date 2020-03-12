{% set duplicity = pillar.get('duplicity', {}) %}
{% set target_port = duplicity.get('target_port', 443) %}


duplicity:
    pkg.installed: []

    # Define a custom temp directory outside /tmp since that is memory-backed and
    # undesirable to use for backups
    file.directory:
        - name: /var/lib/duplicity-temp-dir


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
duplicity-firewall-allow-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - proto: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "duplicity: Allow outgoing dns"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}

duplicity-firewall-allow-outgoing-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - proto: tcp
        - dport: {{ target_port }}
        - match:
            - comment
            - owner
        - comment: "duplicity: Allow outgoing HTTP(S)"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
