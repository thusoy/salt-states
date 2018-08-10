include:
    - .pillar_check


newrelic-sysmond-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https


newrelic-sysmond:
    pkgrepo.managed:
        - name: deb https://apt.newrelic.com/debian/ newrelic non-free
        - key_url: salt://newrelic-sysmond/release-key.gpg
        - require:
            - pkg: newrelic-sysmond-deps

    pkg.installed:
        - name: newrelic-sysmond
        - require:
            - pkgrepo: newrelic-sysmond

    file.managed:
        - name: /etc/newrelic/nrsysmond.cfg
        - source: salt://newrelic-sysmond/nrsysmond.cfg
        - template: jinja

    service.running:
        - name: newrelic-sysmond
        - watch:
            - file: newrelic-sysmond


{% set newrelic_ips = (
    '50.31.164.0/24',
    '162.247.240.0/22',
) %}
newrelic-sysmond-firewall:
    firewall.append:
        - chain: OUTPUT
        - family: ipv4
        - destination: {{ ','.join(newrelic_ips) }}
        - proto: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'newrelic: Allow agent to communicate with NR servers'
        - uid-owner: newrelic
        - jump: ACCEPT
        - require:
            - pkg: newrelic-sysmond


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
newrelic-sysmond-firewall-outgoing-dns-{{ protocol }}-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - destination: system_dns
        - proto: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: "newrelic: Allow DNS for newrelic agent"
        - uid-owner: newrelic
        - jump: ACCEPT
        - require:
            - pkg: newrelic-sysmond
{% endfor %}
{% endfor %}
