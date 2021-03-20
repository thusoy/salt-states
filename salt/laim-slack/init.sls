include:
    - laim


laim-slack:
    cmd.run:
        - name: /opt/venvs/laim/bin/pip install requests==2.25.1 urllib3==1.26.4
        - unless: /opt/venvs/laim/bin/pip freeze | tr -d '\n' | awk '/requests==2.25.1/ && /urllib3==1.26.4/' | grep .
        - require:
            - pkg: laim
        - watch_in:
            - service: laim

    file.managed:
        - name: /etc/laim/handler.py
        - source: salt://laim-slack/handler.py
        - template: jinja
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
