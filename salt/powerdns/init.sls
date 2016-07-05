{% set powerdns = pillar.get('powerdns', {}) -%}

include:
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
        - show_diff: False
        - require:
            - pkg: powerdns

    service.running:
        - name: pdns
        - watch:
            - file: powerdns
            - postgres_user: powerdns

    postgres_user.present:
        - name: pdns
        - password: {{ powerdns.db_password }}
        - refresh_password: True

    postgres_database.present:
        - name: powerdns
        - owner: pdns
        - require:
            - postgres_user: powerdns

    # Add postgres schema
    cmd.run:
        - name: psql
            --no-readline
            --no-password
            -f /etc/powerdns/postgres.sql
            --dbname powerdns
        - unless: psql
            --no-readline
            --no-password
            -c "SELECT * FROM domains LIMIT 1"
            --dbname powerdns
        - runas: 'postgres'
        - require:
            - file: powerdns-db-sql
            - pkg: postgresql-client
            - postgres_database: powerdns
            - postgres_user: powerdns


powerdns-db-sql:
    file.managed:
        - name: /etc/powerdns/postgres.sql
        - source: salt://powerdns/postgres.sql
        - require:
            - pkg: powerdns


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
