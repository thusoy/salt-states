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


# In Stretch apt runs network requests as it's own user _apt
# Convert osmajorrelease to int since it used to be string in older versions of salt
{% set user = '_apt' if grains['os_family'] == 'Debian' and int(grains['osmajorrelease']) >= 9 else 'root' %}

{% for family in ('ipv4', 'ipv6') %}

{% for protocol in ('udp', 'tcp') %}
unattended-upgrades-outbound-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - proto: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'iptables: Allow outgoing DNS for apt'
        - uid-owner: {{ user }}
        - jump: ACCEPT
{% endfor %}


unattended-upgrades-outbound-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dports: 80,443
        - match:
            - comment
            - owner
        - comment: 'unattended-upgrades: Allow apt access to repos'
        - uid-owner: {{ user }}
        - jump: ACCEPT
{% endfor %}
