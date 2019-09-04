rabbitmq-server:
    pkg.installed: []

    file.managed:
        - name: /etc/rabbitmq/rabbitmq.conf
        - source: salt://rabbitmq/rabbitmq.conf

    service.running:
        - require:
            - pkg: rabbitmq-server
        - watch:
            - file: rabbitmq-server
