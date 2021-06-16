{% from 'opentelemetry-collector/map.jinja' import opentelemetry_collector with context %}
{% set version_info = opentelemetry_collector.get('version_info', '0.28.0 sha256=9ae83b23973a2a4057ef5617bd217d8ae561517a877c45a7521b07f5b302cec6') %}
{% set version, checksum = version_info.split() %}

opentelemetry-collector:
    file.managed:
        - name: /usr/local/src/otel-collector_{{ version }}.deb
        - source: https://github.com/open-telemetry/opentelemetry-collector/releases/download/v{{ version }}/otel-collector_{{ version }}_amd64.deb
        - source_hash: {{ checksum }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/otel-collector_{{ version }}.deb
        - watch:
            - file: opentelemetry-collector


opentelemetry-collector-service:
    file.managed:
        - name: /etc/otel-collector/config.yaml
        - source: salt://opentelemetry-collector/config.yaml
        - template: jinja
        - uid: root
        - gid: otel
        - mode: 640
        - show_changes: False
        - require:
            - cmd: opentelemetry-collector

    service.running:
        - name: otel-collector
        - watch:
            - file: opentelemetry-collector-service


{% for family in ('ipv4', 'ipv6') %}

{% for protocol in ('udp', 'tcp') %}
opentelemetry-collector-outgoing-firewall-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'opentelemetry-collector: Allow outgoing DNS'
        - uid-owner: otel
        - require:
            - cmd: opentelemetry-collector
        - jump: ACCEPT
{% endfor %}

opentelemetry-collector-outgoing-firewall-exporter-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dports: {{ opentelemetry_collector.exporter_ports }}
        - match:
            - comment
            - owner
        - comment: 'opentelemetry-collector: Allow exporting'
        - uid-owner: otel
        - require:
            - cmd: opentelemetry-collector
        - jump: ACCEPT
{% endfor %}
