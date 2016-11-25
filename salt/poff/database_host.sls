{% set poff = pillar.get('poff', {}) %}


include:
    - .pillar_check
    - postgres.server
    - powerdns.database_host


poff-database-host:
    postgres_user.present:
        - name: poff
        - password: {{ poff.get('db_password') }}
        - require:
            - pkg: postgres-server

    file.managed:
        - name: /etc/poff/postgres-schema.sql
        - source: salt://poff/poff-postgres-schema.sql
        - makedirs: True

    cmd.wait:
        - name: psql
            --no-readline
            --no-password
            -f /etc/poff/postgres-schema.sql
            --dbname powerdns
        - unless: psql
            --no-readline
            --no-password
            -c "SELECT * FROM dyn_dns_client LIMIT 1"
            --dbname powerdns
        - runas: postgres
        - require:
            - cmd: powerdns-database-host
            - postgres_user: poff-database-host
        - watch:
            - file: poff-database-host


{% for table in (
    'comments',
    'comments_id_seq',
    'cryptokeys',
    'cryptokeys_id_seq',
    'domainmetadata',
    'domainmetadata_id_seq',
    'domains',
    'domains_id_seq',
    'dyn_dns_client',
    'dyn_dns_client_id_seq',
    'records',
    'records_id_seq',
    'supermasters',
    'tsigkeys',
    'tsigkeys_id_seq',
) %}
poff-database-host-table-privilege-{{ table }}:
    postgres_privileges.present:
        - name: poff
        - object_name: {{ table }}
        - object_type: {{ 'sequence' if table.endswith('_seq') else 'table' }}
        - maintenance_db: powerdns
        - privileges:
            - ALL
        - require:
            - cmd: poff-database-host
{% endfor %}
