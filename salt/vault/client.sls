{% from 'vault/map.jinja' import vault with context %}
{% set version, version_hash = vault.version_spec.split(' ') %}


vault-client:
    archive.extracted:
        - name: /usr/local/bin/
        - source: https://releases.hashicorp.com/vault/{{ version }}/vault_{{ version }}_linux_amd64.zip
        - source_hash: {{ version_hash }}
        - archive_format: zip
        - enforce_toplevel: False
        - overwrite: True
        - unless:
            - '/usr/local/bin/vault version | grep -E "^Vault v{{ version }}$"'

    file.managed:
        - name: /etc/vault-ca.pem
        - contents_pillar: vault:client:cacert


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
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


vault-firewall-outbound-client-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 8200
        - match:
            - comment
            - owner
        - comment: 'Vault: Allow communication to other servers'
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
