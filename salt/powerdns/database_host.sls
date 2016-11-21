{% set powerdns = pillar.get('powerdns', {}) %}

include:
    - .pillar_check
    - postgres.server

powerdns-database-host:
    postgres_user.present:
        - name: pdns
        - password: {{ powerdns.get('db_password') }}
        - require:
            - pkg: postgres-server

    postgres_database.present:
        - name: powerdns
        - owner: pdns
        - require:
            - pkg: postgres-server
            - postgres_user: powerdns-database-host

    file.managed:
        - name: /etc/powerdns/postgres.sql
        - source: salt://powerdns/postgres.sql
        - makedirs: True

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
            - file: powerdns-database-host
            - postgres_database: powerdns-database-host
            - postgres_user: powerdns-database-host


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
powerdns-database-host-table-privilege-{{ table }}:
    postgres_privileges.present:
        - name: pdns
        - object_name: {{ table }}
        - object_type: {{ 'sequence' if table.endswith('_seq') else 'table' }}
        - maintenance_db: powerdns
        - privileges:
            - ALL
        - require:
            - cmd: powerdns-database-host
{% endfor %}
