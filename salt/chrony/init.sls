{% set chrony = pillar.get('chrony', {}) %}

chrony:
    pkg.installed: []

    file.managed:
        - name: /etc/chrony/chrony.conf
        - source: salt://chrony/config
        - template: jinja

    service.running:
        - require:
            - pkg: chrony
        - watch:
            - file: chrony


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
chrony-firewall-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'chrony: Allow outbound DNS'
        - uid-owner: _chrony
        - jump: ACCEPT
        - require:
            - pkg: chrony
{% endfor %}

{% set allow_sources = chrony.get('allow_sources_v4', ['0.0.0.0']) if family == 'ipv4' else chrony.get('allow_sources_v6', ['::']) %}
{% for source in allow_sources %}
chrony-firewall-outgoing-{{ family }}-{{ source.replace(':', '-') }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: udp
        - destination: '{{ source }}'
        - sport: 123
        - dport: 123
        - match:
            - comment
            - owner
        - comment: "chrony: Allow outgoing ntp queries"
        - uid-owner: _chrony
        - jump: ACCEPT
        - require:
            - pkg: chrony
{% endfor %}
{% endfor %}
