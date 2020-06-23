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

    pkg.installed:
        - require:
            - pkgrepo: rabbitmq-server

    service.running:
        - require:
            - pkg: rabbitmq-server

    # Remove the guest user
    rabbitmq_user.absent:
        - name: guest
        - require:
            - pkg: rabbitmq-server


{% for family in ('ipv4', 'ipv6') %}
rabbitmq-firewall-inbound-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - match:
            - comment
        - dports: 5672
        - comment: 'rabbitmq: Allow plaintext AMQP'
        - jump: ACCEPT
{% endfor %}
