ntp:
    pkg:
        - installed

    file.managed:
        - name: /etc/ntp.conf
        - source: salt://ntp/ntp.conf
        - template: jinja

    service.running:
        - require:
            - pkg: ntp
        - watch:
            - file: ntp


{% for family in ('ipv4', 'ipv6') %}
ntp-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - proto: udp
        - sport: 123
        - dport: 123
        - match:
            - state
            - comment
        - comment: "ntp: Allow incoming replies to NTP requests"
        - jump: ACCEPT
        - connstate: ESTABLISHED


ntp-firewall-outgoing-{{ family }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - proto: udp
        - sport: 123
        - dport: 123
        - match:
            - comment
            - owner
            - state
        - connstate: NEW,ESTABLISHED
        - uid-owner: root
        - jump: ACCEPT
        - comment: "ntp: Allow outgoing NTP queries for root"
{% endfor %}
