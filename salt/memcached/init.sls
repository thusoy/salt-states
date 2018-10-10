{% set memcached = pillar.get('memcached', {}) %}

include:
     - sasl2


memcached:
    pkg.installed:
        - name: memcached

    file.managed:
        - name: /etc/memcached.conf
        - source: salt://memcached/memcached.conf
        - template: jinja
        - context:
            memory: {{ memcached.get('memory', 64) }}
        - require:
            - pkg: memcached

    service.running:
        - watch:
            - file: memcached


{% for family in ('ipv4', 'ipv6') %}
memcached-iptables-allow-incoming-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - table: filter
        - proto: tcp
        - match:
            - comment
        - comment: 'memcached: Allow incoming'
        - dport: 11211
        - jump: ACCEPT
{% endfor %}
