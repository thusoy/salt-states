{% set http_host = pillar.get('http-host', {}) %}

include:
    - lxc
    - nginx


{% set server_name = 'internal.megacool.co' %}
http-host-nginx-site:
    file.managed:
        - name: /etc/nginx/sites-enabled/http-host
        - source: salt://http-host/nginx-site
        - template: jinja
        - context:
            backend: 127.0.0.1
            backend_port: 8000
            server_name: {{ server_name }}
        - watch_in:
            - service: nginx


http-host-nginx-key:
    file.managed:
        - name: /etc/nginx/private/{{ server_name }}.key
        - contents_pillar: http-host:meowth:key
        - show_diff: False
        - user: root
        - group: nginx
        - mode: 640
        - watch_in:
            - service: nginx


http-host-nginx-cert:
    file.managed:
        - name: /etc/nginx/ssl/{{ server_name }}.crt
        - contents_pillar: http-host:meowth:cert
        - watch_in:
            - service: nginx


http-host-trusted-roots:
    file.managed:
        - name: /etc/nginx/ssl/client-trusted-roots.pem
        - contents_pillar: http-host:client-trusted-roots
        - watch_in:
            - service: nginx
