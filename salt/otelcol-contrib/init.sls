{% from 'otelcol-contrib/map.jinja' import otelcol_contrib with context %}
{% set version, version_hash = otelcol_contrib.get('version_info').split() %}

otelcol-contrib:
    file.managed:
        - name: /usr/local/src/otelcol-contrib.deb
        - source: https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v{{ version }}/otelcol-contrib_{{ version }}_linux_amd64.deb
        - source_hash: {{ version_hash }}

    cmd.watch:
        - name: dpkg -i /usr/local/src/otelcol-contrib.deb
        - watch:
            - file: otelcol-contrib

    service.running:
        - name: otelcol-contrib
        - watch:
            - file: otelcol-contrib


otelcol-contrib-config:
    file.managed:
        - name: /etc/otelcol-contrib/config.yaml
        - source: salt://otelcol-contrib/config.yaml
        - template: jinja
        # Can be secrets embedded here
        - show_changes: False
        - watch_in:
            - service: otelcol-contrib


otelcol-contrib-service-override:
{% if otelcol_contrib.extra_capabilities %}
    file.managed:
        - name: /etc/systemd/system/otelcol-contrib.service.d/override.conf
        - source: salt://otelcol-contrib/override.conf
        - makedirs: True
        - template: jinja
        - require:
            - cmd: otelcol-contrib
{% else %}
    file.absent:
        - name: /etc/systemd/system/otelcol-contrib.service.d/override.conf
{% endif %}

    cmd.watch:
        - name: systemctl daemon-reload
        - watch:
            - file: otelcol-contrib-service-override
        - watch_in:
            - service: otelcol-contrib



{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
otelcol-contrib-firewall-outbound-dns-{{ family }}-{{ protocol }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - destination: system_dns
        - dport: 53
        - match:
            - comment
            - owner
        - comment: 'otelcol-contrib: Allow DNS'
        - uid-owner: otelcol-contrib
        - jump: ACCEPT
        - require:
            - cmd: otelcol-contrib
{% endfor %}


otelcol-contrib-firewall-outbound-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'otelcol-contrib: Allow exporting data over https'
        - uid-owner: otelcol-contrib
        - jump: ACCEPT
        - require:
            - cmd: otelcol-contrib
{% endfor %}
