{% from 'vault/map.jinja' import vault with context %}


vault-client:
    pkgrepo.managed:
        - name: deb [arch=amd64] https://apt.releases.hashicorp.com {{ grains.oscodename }} main
        - key_url: salt://vault/release-key.asc

    pkg.installed:
        - name: vault
        - require:
            - pkgrepo: vault-client

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
