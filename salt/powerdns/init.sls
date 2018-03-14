{% set powerdns = pillar.get('powerdns', {}) -%}

include:
    - .pillar_check
    - postgres.client


{% if powerdns.get('repo') %}
powerdns-deps:
    pkg.installed:
        - name: apt-transport-https
{% endif %}


powerdns:
    {% if powerdns.get('repo') %}
    pkgrepo.managed:
        - name: deb https://repo.powerdns.com/{{ grains.osfullname.lower() }} {{ grains.oscodename }}-{{ powerdns.repo }} main
        - key_url: salt://powerdns/release-key.asc
        - require:
            - pkg: powerdns-deps
        - require_in:
            - pkg: powerdns
    {% endif %}

    pkg.installed:
        - pkgs:
            - pdns-server
            - pdns-backend-pgsql

    file.managed:
        - name: /etc/powerdns/pdns.conf
        - source: salt://powerdns/pdns.conf
        - template: jinja
        - require:
            - pkg: powerdns

    service.running:
        - name: pdns
        - watch:
            - file: powerdns


{% for sample_file in (
    'bindbackend.conf',
    'pdns.d/pdns.simplebind.conf',
    'pdns.d/pdns.local.conf',
) %}
powerdns-default-absent-{{ sample_file }}:
    file.absent:
        - name: /etc/powerdns/{{ sample_file }}
{% endfor %}


powerdns-local-pgsql-conf:
    file.managed:
        - name: /etc/powerdns/pdns.d/pdns.local.gpgsql.conf
        - source: salt://powerdns/pdns.local.gpgsql.conf
        - template: jinja
        - user: root
        - group: pdns
        - mode: 640
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


# powerdns regularly polls for security updates to itself, allow those queries
# https://doc.powerdns.com/md/common/security/#security-polling
powerdns-firewall-allow-secpolls-{{ family }}-{{ proto }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ proto }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'powerdns: Allow polling for security status'
        - uid-owner: pdns
        - jump: ACCEPT


{% for secondary_ip in powerdns.get('allow_axfr_ips', []) %}
powerdns-firewall-allow-axfr-{{ family }}-{{ proto }}-to-{{ secondary_ip }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ proto }}
        - dport: 53
        - destination: {{ secondary_ip}}
        - match:
            - comment
            - owner
        - comment: 'powerdns: Allow AXFR to {{ secondary_ip }}'
        - uid-owner: pdns
        - jump: ACCEPT
{% endfor %}
{% endfor %}


{% set db_host = pillar.get('postgres.host') %}
{% if db_host %}
powerdns-firewall-allow-database-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 5432
        - destination: {{ db_host }}
        - match:
            - comment
            - owner
        - comment: 'powerdns: Allow connecting to database'
        - uid-owner: pdns
        - jump: ACCEPT
{% endif %}
{% endfor %}
