include:
    - .pillar_check
    - apt-transport-https


grafana-deps:
    pkg.installed:
        - name: software-properties-common


grafana:
    pkgrepo.managed:
        - name: deb https://packages.grafana.com/oss/deb stable main
        - key_url: salt://grafana/release-key.asc

    pkg.installed:
        - name: grafana
        - require:
            - pkgrepo: grafana
            - pkg: grafana-deps

    file.managed:
        - name: /etc/grafana/grafana.ini
        - source: salt://grafana/grafana.ini
        - template: jinja
        - user: root
        - group: grafana
        - mode: 640
        - show_changes: False
        - require:
            - pkg: grafana

    service.running:
        - name: grafana-server
        - watch:
            - file: grafana
            - pkg: grafana


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
grafana-outbound-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'grafana: Allow dns'
        - uid-owner: grafana
        - require:
            - pkg: grafana
        - jump: ACCEPT
{% endfor %}


grafana-outbound-firewall-mysql-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 3306
        - match:
            - comment
            - owner
        - comment: 'grafana: Allow access to mysql source'
        - uid-owner: grafana
        - require:
            - pkg: grafana
        - jump: ACCEPT
{% endfor %}
