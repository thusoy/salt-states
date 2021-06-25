include:
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
        - require:
            - pkg: grafana

    service.running:
        - name: grafana-server
        - watch:
            - file: grafana
            - pkg: grafana
