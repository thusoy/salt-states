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


# Ref. https://redis.io/topics/faq#background-saving-fails-with-a-fork-error-under-linux-even-if-i-have-a-lot-of-free-ram
redis-enable-vm-overcommit:
    sysctl.present:
        - name: vm.overcommit_memory
        - value: 1


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
