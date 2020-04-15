redis:
    pkg.installed:
        - name: redis-server

    file.managed:
        - name: /etc/redis/redis.conf
        - source: salt://redis/redis.conf
        - template: jinja
        - require:
            - pkg: redis

    service.running:
        - name: redis-server
        - watch:
            - file: redis
