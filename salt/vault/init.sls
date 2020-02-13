{% from 'vault/map.jinja' import vault with context %}
{% set version, version_hash = vault.version_spec.split(' ') %}
{% set flags = vault.get('flags', []) %}


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


vault-restart:
    cmd.watch:
        - name: service vault restart
        - watch:
            - cmd: vault
            - init_script: vault
