{% from 'postgres/map.jinja' import postgres %}
{% set version = postgres.version %}

include:
    - .pillar_check
    - ca-certificates


postgres-server-repo-key:
    file.managed:
        - name: /usr/share/keyrings/postgresql.gpg
        - source: salt://postgres/release-key.gpg


postgres-server-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/postgresql
        - contents: |
            Package: *
            Pin: origin apt.postgresql.org
            Pin-Priority: 1

            Package: postgresql* libpq5
            Pin: origin apt.postgresql.org
            Pin-Priority: 500


postgres-server-repo:
    file.managed:
        # Install from the archive by default since they have both new and older packages,
        # to enable pinning a specific version
        - name: /etc/apt/sources.list.d/postgresql.list
        - contents: deb [signed-by=/usr/share/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt/ {{ grains.oscodename }}-pgdg main
        - require:
            - file: postgres-server-repo-key

    cmd.watch:
        # Update only the relevant repos to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/postgresql.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - file: postgres-server-repo
        - file: postgres-server-repo-key
        - file: postgres-server-repo-preferences


postgres-server:
    pkg.installed:
        - pkgs:
            - postgresql-{{ version }}{{ '=' + postgres.patch_version if 'patch_version' in postgres else '' }}
            {% if version < 10 %}- postgresql-contrib-{{ version }}{% endif %}
        - require:
            - file: postgres-server-repo-preferences
            - cmd: postgres-server-repo

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
