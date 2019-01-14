{% set acme_dns = pillar.get('acme-dns', {}) %}
{% set extensions_directory = acme_dns.get('extensions-directory', '/usr/local/lib/acme-dns/extensions') %}
{% set saltmaster_user = acme_dns.get('saltmaster-user', 'saltmaster') %}

include:
    - .pillar_check
    - cronic


acme-dns-dependencies:
    pkg.installed:
        - pkgs:
            - python3-dnspython
            - python3-yaml


acme-dns-cronjob:
    cron.present:
        - identifier: acme-dns
        - name: cronic /usr/local/lib/acme-dns/get_certs.py
        - minute: random
        - hour: random


acme-dns-tiny:
    file.managed:
        - name: /usr/local/lib/acme-dns/acme_tiny_dns.py
        - source: salt://acme-dns/acme_tiny_dns.py
        - makedirs: True


acme-dns-get-certs:
    file.managed:
        - name: /usr/local/lib/acme-dns/get_certs.py
        - source: salt://acme-dns/get_certs.py
        - makedirs: True
        - mode: 755


acme-dns-extension-module:
    file.managed:
        - name: {{ extensions_directory }}/pillar/acme_dns.py
        - source: salt://acme-dns/ext_pillar.py
        - makedirs: True


acme-dns-output-directory:
    file.directory:
        - name: /var/lib/acme-dns
        - user: root
        - group: {{ saltmaster_user }}
        - mode: 750


acme-dns-config-file:
    file.managed:
        - name: /etc/acme-dns.yaml
        - source: salt://acme-dns/acme-dns.yaml
        - template: jinja
        - user: root
        - group: {{ saltmaster_user }}
        - mode: 640


{% for family in ('ipv4', 'ipv6') %}

{% for protocol in ('udp', 'tcp') %}
# Allow both the outgoing DNS Update to update the zone (tcp) and
# looking up the nameservers for the zone (tcp+udp)
acme-dns-firewall-outbound-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: 'acme-dns: Allow outbound DNS'
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}


acme-dns-firewall-outbound-acme-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - dport: 443
        - protocol: tcp
        - match:
            - comment
            - owner
        - comment: 'acme-dns: Allow outbound ACME requests'
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
