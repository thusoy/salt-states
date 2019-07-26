{% set rsyslog = pillar.get('rsyslog', {}) %}

rsyslog:
    pkg.installed:
        - pkgs:
            - rsyslog
            - rsyslog-gnutls

    file.managed:
        - name: /etc/rsyslog.conf
        - source: salt://rsyslog/rsyslog.conf
        - template: jinja

    service.running:
        - watch:
            - file: rsyslog


{% for name in rsyslog.get('configs', {}) %}
rsyslog-config-{{ name }}:
    file.managed:
        - name: /etc/rsyslog.d/{{ name }}.conf
        - contents_pillar: rsyslog:configs:{{ name }}
        - require:
            - pkg: rsyslog
        - watch_in:
            - service: rsyslog
{% endfor %}
