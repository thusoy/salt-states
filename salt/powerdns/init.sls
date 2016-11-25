{% set powerdns = pillar.get('powerdns', {}) -%}

include:
    - .pillar_check
    - postgres.client


powerdns:
    pkg.installed:
        - pkgs:
            - pdns-server
            - pdns-backend-pgsql

    file.managed:
        - name: /etc/powerdns/pdns.conf
        - source: salt://powerdns/pdns.conf
        - user: root
        - group: pdns
        - mode: 640
        - template: jinja
        - show_changes: False
        - require:
            - pkg: powerdns

    service.running:
        - name: pdns
        - watch:
            - file: powerdns


powerdns-local-pgsql-conf:
    file.managed:
        - name: /etc/powerdns/pdns.d/pdns.local.gpgsql.conf
        - source: salt://powerdns/pdns.local.gpgsql.conf
        - template: jinja
        - show_changes: False
        - require:
            - pkg: powerdns
        - watch_in:
            - service: powerdns


{% for family in ('ipv4', 'ipv6') %}
{% for proto in ('udp', 'tcp') %}
powerdns-firewall-{{ proto }}-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - proto: {{ proto }}
        - match: comment
        - comment: "powerdns: Allow incoming DNS requests"
        - dport: 53
        - jump: ACCEPT
{% endfor %}
{% endfor %}
