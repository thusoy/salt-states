include:
    - apt-transport-https


rabbitmq-erlang-repo:
    pkgrepo.managed:
        - name: deb https://dl.bintray.com/rabbitmq-erlang/debian buster erlang
        - key_url: salt://rabbitmq/release-key.asc


rabbitmq-server:
    pkgrepo.managed:
        - name: deb https://dl.bintray.com/rabbitmq/debian buster main
        - key_url: salt://rabbitmq/release-key.asc

    file.managed:
        - name: /etc/rabbitmq/rabbitmq.conf
        - source: salt://rabbitmq/rabbitmq.conf

    pkg.installed:
        - require:
            - pkgrepo: rabbitmq-server

    service.running:
        - require:
            - pkg: rabbitmq-server
        - watch:
            - file: rabbitmq-server

    # Remove the guest user
    rabbitmq_user.absent:
        - name: guest
        - require:
            - pkg: rabbitmq-server
