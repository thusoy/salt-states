unattended-upgrades:
    pkg.installed:
        - pkgs:
            - apt-listchanges
            - unattended-upgrades

    file.managed:
        - name: /etc/apt/apt.conf.d/50unattended-upgrades
        - source: salt://unattended-upgrades/50unattended-upgrades
        - template: jinja


unattended-upgrades-periodic-upgrade:
    file.managed:
        - name: /etc/apt/apt.conf.d/02periodic
        - source: salt://unattended-upgrades/02periodic
        - template: jinja


unattended-upgrades-apt-listchanges:
    file.managed:
        - name: /etc/apt/listchanges.conf
        - source: salt://unattended-upgrades/listchanges.conf
        - template: jinja


{% for family in ('ipv4', 'ipv6') %}
unattended-upgrades-outbound-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dports: 80,443
        - match:
            - comment
            - owner
        - comment: 'unattended-upgrades: Allow root access to apt mirrors/HTTP(S)'
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
