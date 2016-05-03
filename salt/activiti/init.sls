{% from 'macros.jinja' import nginx_site_pillar %}

{% set version_spec = '5.18.0 sha256=1de93d9d27cbe4bd708452cb96a6fb9c1e63f3dc029cd81ab29b48ebee36f9bc' %}
{% set version, source_hash = version_spec.split() %}
{% set webapp_root = '/srv/tomcat-webapps' %}
{% set postgres_driver_version_spec = '9.4-1202.jdbc41 sha256=907e8a73dd2b9fe79798feaf627e6ba7c729ce7e889e72ec3efcd1457959083c' %}
{% set postgres_driver_version, postgres_driver_hash = postgres_driver_version_spec.split() %}

include:
    - .pillar_check
    - postgres.server
    - tomcat


activiti-deps:
    pkg.installed:
        - pkgs:
            - unzip


activiti:
    file.managed:
        - name: /usr/local/src/activiti-{{ version }}.zip
        - source: https://github.com/Activiti/Activiti/releases/download/activiti-{{ version }}/activiti-{{ version }}.zip
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: cd /usr/local/src &&
                unzip activiti-{{ version }}.zip &&
                unzip activiti-{{ version }}/wars/activiti-explorer.war -d {{ webapp_root }}/ROOT &&
                unzip activiti-{{ version }}/wars/activiti-rest.war -d {{ webapp_root }}/activiti-rest
        - require:
            - file: tomcat-webapp-dir
            - pkg: activiti-deps
        - watch:
            - file: activiti
        - watch_in:
            - service: tomcat

    postgres_user.present:
        - name: activiti
        - password: {{ salt['pillar.get']('activiti:db_password') }}

    postgres_database.present:
        - name: activiti
        - owner: activiti
        - require:
            - postgres_user: activiti


{% for role in ('admin', 'user') %}
activiti-{{ role }}-role:
    cmd.run:
        - name: psql
                --no-readline
                --no-password
                --dbname activiti
                -c "INSERT INTO act_id_group (id_, rev_, name_, type_) VALUES (
                    '{{ role }}',
                    1,
                    '{{ role.title() }}',
                    'security-role'
                    );"
        - user: postgres
        - unless: role_exists=$(psql
                  --no-readline
                  --no-password
                  --tuples-only
                  --no-align
                  --dbname activiti
                  -c "SELECT count(*) FROM act_id_group where id_='{{ role }}';") &&
                  [ $role_exists = "1" ] && exit 0 || exit 1
{% endfor %}


{% for user, password, role in [
    ('admin', salt['pillar.get']('activiti:admin_password'), 'admin'),
    ('restuser', salt['pillar.get']('activiti:rest_password'), 'user'),
] %}
activiti-{{ user }}-user:
    cmd.run:
        - name: psql
                --no-readline
                --no-password
                --dbname activiti
                -c "INSERT INTO act_id_user (id_, rev_, pwd_) VALUES (
                    '{{ user }}',
                    1,
                    '{{ password }}'
                    );
                    INSERT INTO act_id_membership VALUES (
                    '{{ user }}',
                    '{{ role }}'
                    );"
        - user: postgres
        - unless: user_exists=$(psql
                  --no-readline
                  --no-password
                  --tuples-only
                  --no-align
                  --dbname activiti
                  -c "SELECT count(*) FROM act_id_user where id_='{{ user }}';") &&
                  [ $user_exists = "1" ] && exit 0 || exit 1
{% endfor %}

{% for app in ('ROOT', 'activiti-rest') %}
activiti-{{ app }}-postgres-driver:
    file.managed:
        - name: {{ webapp_root }}/{{ app }}/WEB-INF/lib/postgresql-{{ postgres_driver_version }}.jar
        - source: https://jdbc.postgresql.org/download/postgresql-{{ postgres_driver_version }}.jar
        - source_hash: {{ postgres_driver_hash }}
        - require:
            - cmd: activiti
        - watch_in:
            - service: tomcat


activiti-{{ app }}-config:
    file.managed:
        - name: {{ webapp_root }}/{{ app }}/WEB-INF/lib/activiti.cfg.xml
        - source: salt://activiti/activiti.cfg.xml
        - require:
            - cmd: activiti
        - watch_in:
            - service: tomcat


activiti-{{ app }}-engine-properties:
    file.managed:
        - name: {{ webapp_root }}/{{ app }}/WEB-INF/classes/engine.properties
        - source: salt://activiti/engine.properties
        - require:
            - cmd: activiti
        - watch_in:
            - service: tomcat


activiti-{{ app }}-db-properties:
    file.managed:
        - name: {{ webapp_root }}/{{ app }}/WEB-INF/classes/db.properties
        - source: salt://activiti/db.properties
        - template: jinja
        - user: root
        - group: tomcat7
        - mode: 640
        - require:
            - cmd: activiti
        - watch_in:
            - service: tomcat
{% endfor %}


{% for family in ('ipv4', 'ipv6') %}
activiti-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - table: filter
        - proto: tcp
        - dport: 8080
        - match:
            - comment
            - state
        - comment: "activiti: Allow incoming HTTP from local subnet"
        - connstate: NEW,ESTABLISHED
        - jump: ACCEPT
{% endfor %}
