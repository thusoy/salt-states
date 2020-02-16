{% set temp_vault = pillar.get('vault', {}) %}
{% set dev = temp_vault.get('dev') %}
{% if dev %}
    {% from 'vault/map-dev.jinja' import vault with context %}
{% else %}
    {% from 'vault/map.jinja' import vault with context %}
{% endif %}
{% set version, version_hash = vault.version_spec.split(' ') %}
{% set flags = vault.get('flags', []) %}


include:
    - .pillar_check


vault-user:
    user.present:
        - name: vault
        - fullname: vault worker
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin


vault-config-directory:
    file.directory:
        - name: /etc/vault
        - user: root
        - group: vault
        - mode: 750
        - require:
            - user: vault-user


vault:
    pkg.installed:
        - name: libcap2-bin

    archive.extracted:
        - name: /usr/local/bin/
        - source: https://releases.hashicorp.com/vault/{{ version }}/vault_{{ version }}_linux_amd64.zip
        - source_hash: {{ version_hash }}
        - archive_format: zip
        - enforce_toplevel: False
        - overwrite: True
        - unless:
            - '/usr/local/bin/vault version | grep -E "^Vault v{{ version }}$"'

    cmd.watch:
        - name: 'setcap cap_ipc_lock=+ep /usr/local/bin/vault'
        - require:
            - pkg: vault
        - watch:
            - archive: vault

    init_script.managed:
        - systemd: salt://vault/job-systemd
        - template: jinja
        - context:
            flags: {{ flags | json }}
            {% if vault.get('auth') %}
            environment_variables:
                {% for auth_name, auth_properties in vault.get('auth', {}).items() %}
                {{ auth_properties.environment_variable_name }}: /etc/vault/{{ auth_properties.filename }}
                {% endfor %}
            {% else %}
            environment_variables: {}
            {% endif %}

    file.managed:
        - name: /etc/vault/config.json
        - template: jinja
        - source: salt://vault/config
        - context:
            config: {{ vault.get('config', {}) | json }}
        - user: root
        - group: vault
        - mode: 640
        - require:
            - user: vault-user

    service.running:
        - enable: True
        - reload: True
        # Don't watch on the archive since an upgrade requires a restart and manual unsealing
        # If the init file changes we probably need a restart too for anything to take effect
        - require:
            - cmd: vault
            - init_script: vault
        - watch:
            - file: vault
            {% if not dev %}
            - file: vault-tls-cert
            - file: vault-tls-key
            {% endif %}


{% if not dev %}
vault-tls-cert:
    file.managed:
        - name: /etc/vault/cert.pem
        - user: root
        - group: vault
        - mode: 644
        - contents_pillar: vault:tls_cert


vault-tls-key:
    file.managed:
        - name: /etc/vault/key.pem
        - user: root
        - group: vault
        - mode: 640
        - show_changes: False
        - contents_pillar: vault:tls_key
{% endif %}


# This assumes Vault is being run on the standard ports and binding to 0.0.0.0,
# otherwise we'd have to parse the listener address.
{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
vault-firewall-outbound-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - destination: system_dns
        - dport: 53
        - match:
            - comment
            - owner
        - comment: 'Vault: Allow DNS'
        - uid-owner: vault
        - jump: ACCEPT
        - require:
            - user: vault-user
{% endfor %}


vault-firewall-outbound-server-to-server-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 8201
        - match:
            - comment
            - owner
        - comment: 'Vault: Allow communication to other servers'
        - uid-owner: vault
        - jump: ACCEPT
        - require:
            - user: vault-user


vault-firewall-inbound-server-to-server-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - dport: 8201
        - match:
            - comment
        - comment: 'Vault: Allow communication from other servers'
        - jump: ACCEPT


vault-firewall-inbound-client-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - dport: 8200
        - match:
            - comment
        - comment: 'Vault: Allow client communication'
{% endfor %}


vault-restart:
    cmd.watch:
        - name: service vault restart
        - watch:
            - cmd: vault
            - init_script: vault


{% for auth_name, auth_properties in vault.get('auth', {}).items() %}
vault-auth-{{ auth_name }}:
    file.managed:
        - name: /etc/vault/{{ auth_properties.filename }}
        - user: root
        - group: vault
        - mode: 640
        - contents_pillar: vault:auth:{{ auth_name }}:secret
        - show_changes: False
        - require:
            - user: vault-user
            - file: vault-config-directory
        - watch_in:
            - cmd: vault-restart
{% endfor %}
