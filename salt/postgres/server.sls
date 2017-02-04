{% from 'postgres/map.jinja' import postgres %}
{% set version = postgres.version %}

include:
    - .pillar_check


postgres-server-deps:
    pkg.installed:
        - name: apt-transport-https


postgres-server:
    pkgrepo.managed:
        - name: deb https://apt.postgresql.org/pub/repos/apt/ {{ grains.oscodename }}-pgdg main
        - key_url: salt://postgres/release-key.asc
        - require:
            - pkg: postgres-server-deps

    pkg.installed:
        - pkgs:
            - postgresql-{{ version }}
            - postgres-contrib-{{ version }}
        - require:
            - pkgrepo: postgres-server

    file.managed:
        - name: /etc/postgresql/{{ version }}/main/pg_hba.conf
        - source: salt://postgres/pg_hba.conf
        - template: jinja
        - context:
            internal: {{ postgres.internal }}
            cert_auth: {{ postgres.cert_auth }}
        - user: postgres
        - group: postgres
        - mode: 640
        - require:
            - pkg: postgres-server

    service.running:
        - name: postgresql
        - require:
            - pkg: postgres-server
        - watch:
            - file: postgres-server
            - file: postgres-server-config


postgres-server-config:
    file.managed:
        - name: /etc/postgresql/{{ version }}/main/postgresql.conf
        - source: salt://postgres/postgresql.conf
        - template: jinja
        - watch_in:
            - service: postgres-server


{% if not postgres.internal %}

{% for family in ('ipv4', 'ipv6') %}
postgres-server-iptables-allow-incoming-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - table: filter
        - proto: tcp
        - match:
            - comment
        - comment: 'postgresql: Allow incoming'
        - dport: 5432
        - jump: ACCEPT
        - save: True
{% endfor %}


postgres-server-cert:
    file.managed:
        - name: /etc/postgresql/{{ version }}/main/cert.crt
        - contents_pillar: postgres:cert
        - watch_in:
            - service: postgres-server


postgres-server-key:
    file.managed:
        - name: /etc/postgresql/{{ version }}/main/key.key
        - contents_pillar: postgres:key
        - user: root
        - group: postgres
        - mode: 640
        - watch_in:
            - service: postgres-server

{% endif %}
