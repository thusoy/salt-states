{% set temp_vault = pillar.get('vault', {}) %}
{% set dev = temp_vault.get('dev') %}
{% if dev %}
    {% from 'vault/map-dev.jinja' import vault with context %}
{% else %}
    {% from 'vault/map.jinja' import vault with context %}
{% endif %}
{% set flags = vault.get('flags', []) %}


include:
    - .repo
    - .pillar_check


vault-server-config-directory:
    file.directory:
        - name: /etc/vault
        - user: root
        - group: vault
        - mode: 750
        - require:
            - pkg: vault


vault:
    pkg.installed:
        - name: vault
        - require:
            - cmd: vault-repo-preferences

    init_script.managed:
        - systemd: salt://vault/job-systemd
        - template: jinja
        - context:
            flags: {{ flags | json }}
            {% if vault.get('auth') %}
            environment_variables:
                {% for auth_name, auth_properties in vault.get('auth', {}).items() %}
                {{ auth_properties.environment_variable_name }}: /etc/vault/{{ auth_properties.get('filename') }}
                {% endfor %}
            {% else %}
            environment_variables: {}
            {% endif %}

    file.managed:
        - name: /etc/vault/config.json
        - template: jinja
        - source: salt://vault/server_config
        - context:
            config: {{ salt['mdl_saltdata.resolve_leaf_values'](vault.get('server_config', {})) | json }}
        - user: root
        - group: vault
        - mode: 640
        - require:
            - pkg: vault

    service.running:
        - enable: True
        - reload: True
        # Don't watch on the archive since an upgrade requires a restart and manual unsealing
        # If the init file changes we probably need a restart too for anything to take effect
        - require:
            - pkg: vault
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
        - name: /etc/vault-ca.pem
        - user: root
        - group: vault
        - mode: 644
        - contents_pillar: vault:tls_cert
        - require:
            - pkg: vault


vault-tls-key:
    file.managed:
        - name: /etc/vault/key.pem
        - user: root
        - group: vault
        - mode: 640
        - show_changes: False
        - contents_pillar: vault:tls_key
        - require:
            - pkg: vault
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
            - pkg: vault
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
            - pkg: vault


vault-firewall-outbound-minion-to-server-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 8200
        - match:
            - comment
            - owner
        - comment: 'Vault: Allow salt minion to communicate with servers'
        - uid-owner: root
        - jump: ACCEPT


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
        - jump: ACCEPT


vault-firewall-outbound-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'vault: Allow communicating with storage and auth backends over HTTPS'
        - uid-owner: vault
        - jump: ACCEPT
        - require:
            - pkg: vault
{% endfor %}


vault-restart:
    cmd.watch:
        - name: service vault restart
        - watch:
            - pkg: vault
            - init_script: vault


{% for auth_name, auth_properties in vault.get('auth', {}).items() %}
vault-auth-{{ auth_name }}:
    file.managed:
        - name: /etc/vault/{{ auth_properties.get('filename') }}
        - user: root
        - group: vault
        - mode: 640
        {% if 'secret' in auth_properties %}
        - contents_pillar: vault:auth:{{ auth_name }}:secret
        {% else %}
        - contents_pillar: {{ auth_properties.secret_pillar }}
        {% endif %}
        - show_changes: False
        - require:
            - pkg: vault
            - file: vault-server-config-directory
        - watch_in:
            - cmd: vault-restart
{% endfor %}
