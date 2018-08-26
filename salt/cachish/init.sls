cachish:
    pkgrepo.managed:
        - name: deb https://thusoy-apt.s3-accelerate.amazonaws.com/apt/debian {{ grains.oscodename }} main
        - key_url: salt://cachish/release-key.asc

    pkg.installed:
        - require:
            - pkgrepo: cachish

    file.managed:
        - name: /etc/cachish.yml
        - source: salt://cachish/config.yml
        - template: jinja
        - show_changes: False
        - user: root
        - group: cachish
        - mode: 640
        - require:
            - pkg: cachish

    service.running:
        - watch:
            - file: cachish


{% for family in ('ipv4', 'ipv6') %}
cachish-outgoing-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'cachish: Allow outgoing traffic'
        - uid-owner: cachish
        - jump: ACCEPT
        - require:
            - pkg: cachish


{% for protocol in ('tcp', 'udp') %}
cachish-outgoing-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'cachish: Allow outgoing DNS'
        - uid-owner: cachish
        - jump: ACCEPT
        - require:
            - pkg: cachish
{% endfor %}
{% endfor %}
