{% from 'vault/map.jinja' import vault with context %}
{% set version, version_hash = vault.version_spec.split(' ') %}
{% set flags = vault.get('flags', []) %}


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

    user.present:
        - name: vault
        - fullname: vault worker
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin

    file.managed:
        - name: /etc/vault.json
        - template: jinja
        - source: salt://vault/config
        - context:
            config: {{ vault.get('config', {}) | json }}
        - user: root
        - group: vault
        - mode: 640
        - require:
            - user: vault

    service.running:
        - enable: True
        - reload: True
        # Don't watch on the archive since an upgrade requires a restart and manual unsealing
        - require:
            - cmd: vault
        - watch:
            - file: vault
            - init_script: vault


vault-restart:
    cmd.watch:
        - name: service vault restart
        - watch:
            - cmd: vault
