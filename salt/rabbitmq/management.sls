{% from 'rabbitmq/map.jinja' import rabbitmq with context %}

include:
    - .
    - .management_pillar_check


rabbitmq-management-plugin:
    file.managed:
        - name: /etc/rabbitmq/rabbitmq.conf
        - template: jinja
        - source: salt://rabbitmq/rabbitmq.conf
        - require:
            - pkg: rabbitmq-server
        - watch_in:
            - service: rabbitmq-server

    rabbitmq_plugin.enabled:
        - name: rabbitmq_management
        - require:
            - pkg: rabbitmq-server


rabbitmq-management-user-admin:
    rabbitmq_user.present:
        - name: admin
        - password: {{ rabbitmq.get('admin_password') }}
        - tags: administrator
        - require:
            - rabbitmq_plugin: rabbitmq-management-plugin


rabbitmq-management-user-monitoring:
    rabbitmq_user.present:
        - name: monitoring
        - password: {{ rabbitmq.get('monitoring_password') }}
        - tags: monitoring
        - require:
            - rabbitmq_plugin: rabbitmq-management-plugin


{% if not rabbitmq.management_plaintext %}
rabbitmq_management-tls-cert:
    file.managed:
        - name: /etc/rabbitmq/cert.pem
        - contents_pillar: rabbitmq:management_tls_cert
        - watch_in:
            - service: rabbitmq-server


rabbitmq-management-tls-key:
    file.managed:
        - name: /etc/rabbitmq/key.pem
        - contents_pillar: rabbitmq:management_tls_key
        - user: root
        - group: rabbitmq
        - mode: 640
        - show_changes: False
        - require:
            - pkg: rabbitmq-server
        - watch_in:
            - service: rabbitmq-server


{% for family in ('ipv4', 'ipv6') %}
rabbitmq-management-firewall-inbound-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - match:
            - comment
        - dport: {{ rabbitmq.management_ssl_port }}
        - comment: 'rabbitmq.management: Allow https'
        - jump: ACCEPT
{% endfor %}

{% else %}

{% for family in ('ipv4', 'ipv6') %}
rabbitmq-management-firewall-inbound-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - match:
            - comment
        - dport: {{ rabbitmq.management_port }}
        - comment: 'rabbitmq.management: Allow http'
        - jump: ACCEPT
{% endfor %}

{% endif %}
