# Hart installs itself when it creates the saltmaster, so we only need to add
# the configuration and firewall rules
hart:
    file.managed:
        - name: /etc/hart.toml
        - source: salt://hart/config.toml
        - template: jinja
        - user: root
        - group: root
        - mode: 640
        - show_changes: False


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
hart-firewall-allow-outgoing-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "hart: Allow outgoing dns"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


hart-firewall-allow-outgoing-ssh-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dports: 22,443
        - match:
            - comment
            - owner
        - comment: "hart: Allow outgoing SSH and HTTPS"
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
