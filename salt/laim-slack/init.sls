include:
    - laim


laim-slack:
    pkg.installed:
        - name: python3-requests

    file.managed:
        - name: /etc/laim/handler.py
        - source: salt://laim-slack/handler.py
        - template: jinja
        - require:
            - pkg: laim-slack
        - watch_in:
            - service: laim


{% for family in ('ipv4', 'ipv6') %}
laim-slack-outgoing-firewall-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: "laim-slack: Allow outgoing HTTPS"
        - uid-owner: laim
        - jump: ACCEPT
        - require:
            - pkg: laim


{% for protocol in ('tcp', 'udp') %}
laim-slack-outgoing-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'laim-slack: Allow outgoing DNS'
        - uid-owner: laim
        - jump: ACCEPT
        - require:
            - pkg: laim
{% endfor %}
{% endfor %}
