{% from 'rabbitmq/map.jinja' import rabbitmq with context %}


rabbitmq-repo-key-erlang:
    file.managed:
        - name: /usr/share/keyrings/rabbitmq-erlang.gpg
        - source: salt://rabbitmq/release-key.E495BB49CC4BBE5B.gpg


rabbitmq-repo-key-rabbitmq:
    file.managed:
        - name: /usr/share/keyrings/rabbitmq-server.gpg
        - source: salt://rabbitmq/release-key.9F4587F226208342.gpg


rabbitmq-repo:
    file.managed:
        - name: /etc/apt/sources.list.d/rabbitmq.list
        - contents: |
            deb [signed-by=/usr/share/keyrings/rabbitmq-erlang.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/debian {{ grains.oscodename }} main
            deb [signed-by=/usr/share/keyrings/rabbitmq-server.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/debian {{ grains.oscodename }} main
        - require:
            - file: rabbitmq-repo-key-erlang
            - file: rabbitmq-repo-key-rabbitmq


rabbitmq-repo-preferences:
    file.managed:
        - name: /etc/apt/preferences.d/rabbitmq
        - contents: |
            Package: *
            Pin: origin ppa1.rabbitmq.com
            Pin-Priority: 1

            Package: erlang*
            {% if 'erlang_version' in rabbitmq -%}
            {# Can't pin both origin and version -#}
            Pin: version {{ rabbitmq.erlang_version }}
            Pin-Priority: 1001
            {% else -%}
            Pin: origin ppa1.rabbitmq.com
            Pin-Priority: 500
            {% endif %}

            Package: rabbitmq-server
            Pin: origin ppa1.rabbitmq.com
            Pin-Priority: 500


rabbitmq-server:
    cmd.watch:
        # Update only the relevant repos to keep this fast
        - name: apt-get update -y -o Dir::Etc::sourcelist="sources.list.d/rabbitmq.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"
        - watch:
            - file: rabbitmq-repo-key-erlang
            - file: rabbitmq-repo-key-rabbitmq
            - file: rabbitmq-repo
            - file: rabbitmq-repo-preferences


    pkg.installed:
        - pkgs:
            - rabbitmq-server: {{ rabbitmq.get('version', '~') }}
            - erlang-base: {{ rabbitmq.get('erlang_version', '~') }}
        - require:
            - cmd: rabbitmq-server

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
