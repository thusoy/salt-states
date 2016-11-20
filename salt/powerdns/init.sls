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
            - postgres_user: powerdns

    postgres_user.present:
        - name: pdns
        - password: {{ powerdns.get('db_password') }}
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


{% for table in (
    'comments',
    'comments_id_seq',
    'cryptokeys',
    'cryptokeys_id_seq',
    'domainmetadata',
    'domainmetadata_id_seq',
    'domains',
    'domains_id_seq',
    'records',
    'records_id_seq',
    'supermasters',
    'tsigkeys',
    'tsigkeys_id_seq',
) %}
powerdns-privilege-{{ table }}:
    postgres_privileges.present:
        - name: pdns
        - object_name: {{ table }}
        - object_type: {{ 'sequence' if table.endswith('_seq') else 'table' }}
        - maintenance_db: powerdns
        - privileges:
            - ALL
        - require:
            - postgres_user: powerdns
            - postgres_database: powerdns
{% endfor %}


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
