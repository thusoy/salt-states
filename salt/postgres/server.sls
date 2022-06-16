{% from 'postgres/map.jinja' import postgres %}
{% set version = postgres.version %}

include:
    - .pillar_check
    - ca-certificates


postgres-server-deps:
    pkg.installed:
        - name: apt-transport-https

postgres-server:
    pkgrepo.managed:
        # Install from the archive by default since they have both new and older packages,
        # to enable pinning a specific version
        - name: deb https://apt-archive.postgresql.org/pub/repos/apt/ {{ grains.oscodename }}-pgdg-archive main
        - key_url: salt://postgres/release-key.asc
        - require:
            - pkg: postgres-server-deps

    pkg.installed:
        - pkgs:
            - postgresql-{{ version }}{{ '=' + postgres.patch_version if 'patch_version' in postgres else '' }}
            {% if version < 10 %}- postgresql-contrib-{{ version }}{% endif %}
        - require:
            - pkgrepo: postgres-server

    file.managed:
        - name: /etc/postgresql/{{ version }}/main/pg_hba.conf
        - source: salt://postgres/pg_hba.conf
        - template: jinja
        - context:
            internal: {{ postgres.internal }}
            cert_auth: {{ postgres.cert_auth }}
            external_nossl: {{ postgres.external_nossl }}
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

{% if not postgres.external_nossl %}
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
        - show_changes: False
        - watch_in:
            - service: postgres-server

{% endif %}
{% endif %}
