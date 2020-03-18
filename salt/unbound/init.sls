unbound:
    pkg.installed: []

    file.managed:
        - name: /etc/unbound/unbound.conf
        - source: salt://unbound/config.conf
        - template: jinja
        - require:
            - pkg: unbound

    service.running:
        - watch:
            - file: unbound


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
unbound-firewall-outgoing-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: 'unbound: Allow outbound dns'
        - uid-owner: unbound
        - jump: ACCEPT
        - require:
            - pkg: unbound
{% endfor %}
{% endfor %}
