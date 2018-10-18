{% set memcached = pillar.get('memcached', {}) %}
{% set port = memcached.get('port', 11211) %}

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
            port: {{ port }}
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
        - dport: {{ port }}
        - jump: ACCEPT
{% endfor %}
