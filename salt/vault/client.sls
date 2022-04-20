{% from 'vault/map.jinja' import vault with context %}

vault-client-repo-key:
    file.managed:
        - name: /usr/share/keyrings/hashicorp-archive-keyring.gpg
        - source: salt://vault/release-key.gpg


vault-client-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/hashicorp.list
        # Restrict repo key to only be usable for the hashicorp repo
        - contents: deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg arch=amd64] https://apt.releases.hashicorp.com {{ grains.oscodename }} main
        - require:
            - file: vault-client-repo-key


# Prevent the repo from upgrading any other packages (ref https://linux.die.net/man/5/apt_preferences)
vault-client-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/hashicorp-vault.pref
        - contents: |
            Package: *
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 1

            Package: vault
            Pin: origin apt.releases.hashicorp.com
            Pin-Priority: 500

    cmd.watch:
        - name: apt-get update -y
        - watch:
            - file: vault-client-repo
            - file: vault-client-repo-key
            - file: vault-client-repo-preferences


vault-client:
    pkg.installed:
        - name: vault
        - require:
            - cmd: vault-client-repo-preferences

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
        - comment: 'Vault: Allow DNS'
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
        - comment: 'Vault: Allow communication to other servers'
        - jump: ACCEPT
{% endfor %}
