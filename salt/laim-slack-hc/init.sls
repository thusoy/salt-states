include:
    - laim


laim-slack-hc:
    cmd.run:
        - name: /opt/venvs/laim/bin/pip install requests==2.22.0
        - unless: /opt/venvs/laim/bin/pip freeze | grep requests==2.22.0
        - require:
            - pkg: laim
        - watch_in:
            - service: laim

    file.managed:
        - name: /etc/laim/handler.py
        - source: salt://laim-slack-hc/handler.py
        - template: jinja
        - watch_in:
            - service: laim


{% for family in ('ipv4', 'ipv6') %}
laim-slack-hc-outgoing-firewall-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: "laim-slack-hc: Allow outgoing HTTPS"
        - uid-owner: laim
        - jump: ACCEPT
        - require:
            - pkg: laim


{% for protocol in ('tcp', 'udp') %}
laim-slack-hc-outgoing-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'laim-slack-hc: Allow outgoing DNS'
        - uid-owner: laim
        - jump: ACCEPT
        - require:
            - pkg: laim
{% endfor %}
{% endfor %}
