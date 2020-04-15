redis:
    pkg.installed:
        - name: redis-server

    file.managed:
        - name: /etc/redis/redis.conf
        - source: salt://redis/redis.conf
        - template: jinja
        - user: root
        - group: redis
        - mode: 640
        - show_changes: False
        - require:
            - pkg: redis

    service.running:
        - name: redis-server
        - watch:
            - file: redis


{% for family in ('ipv4', 'ipv6') %}
redis-inbound-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - proto: tcp
        - dport: 6379
        - match:
            - comment
        - comment: 'redis: Allow incoming connections'
        - jump: ACCEPT
{% endfor %}
