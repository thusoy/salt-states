include:
    - apt-transport-https


rabbitmq-erlang-repo:
    pkgrepo.managed:
        - name: deb https://dl.cloudsmith.io/public/rabbitmq/rabbitmq-erlang/deb/debian {{ grains.oscodename }} main
        - key_url: salt://rabbitmq/release-key-erlang.asc


rabbitmq-server:
    pkgrepo.managed:
        - name: deb https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ {{ grains.oscodename }} main
        - key_url: salt://rabbitmq/release-key-rabbitmq.asc

    pkg.installed:
        - require:
            - pkgrepo: rabbitmq-erlang-repo
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
