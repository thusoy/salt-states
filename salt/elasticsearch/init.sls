{% from 'elasticsearch/map.jinja' import elasticsearch with context -%}

include:
    - .pillar_check


elasticsearch-deps:
    pkg.installed:
        - name: apt-transport-https


elasticsearch:
    # add repo to managed repositories
    pkgrepo.managed:
        - name: deb https://artifacts.elastic.co/packages/7.x/apt stable main
        - key_url: salt://elasticsearch/release-key
        - require:
            - pkg: elasticsearch-deps

    # install elastic search package
    pkg.installed:
        - name: elasticsearch
        - require:
            - pkgrepo: elasticsearch
        - version: {{ elasticsearch.version }}

    # start service and watch the config files for restarting the service
    service.running:
        - require:
            - file: elasticsearch
        - watch:
            - file: elasticsearch-environment-variables
            - file: elasticsearch-jvm-options
            - file: elasticsearch-elasticsearch-yml
            - file: elasticsearch-logging-config
            - file: elasticsearch-data-dir
            - pkg: elasticsearch

    # Created a dedicated temp directory to not conflict with hardening of /tmp
    file.directory:
        - name: /var/lib/elasticsearch-temp
        - makedirs: True
        - user: root
        - group: elasticsearch
        - mode: 775
        - require:
            - pkg: elasticsearch


elasticsearch-environment-variables:
    file.managed:
        - name: /etc/default/elasticsearch
        - source: salt://elasticsearch/default


elasticsearch-jvm-options:
    file.managed:
        - name: /etc/elasticsearch/jvm.options
        - source: salt://elasticsearch/jvm.options
        - template: jinja


elasticsearch-elasticsearch-yml:
    file.managed:
        - name: /etc/elasticsearch/elasticsearch.yml
        - source: salt://elasticsearch/elasticsearch.yml
        - template: jinja


elasticsearch-logging-config:
    file.managed:
        - name: /etc/elasticsearch/log4j2.properties
        - source: salt://elasticsearch/log4j2.properties
        - template: jinja


elasticsearch-data-dir:
    file.directory:
        - name: {{ elasticsearch.data_dir }}
        - user: elasticsearch
        - group: elasticsearch
        - mode: 2750
        - require:
             - pkg: elasticsearch


{% for family in ('ipv4', 'ipv6') %}
{% for protocol in ('udp', 'tcp') %}
elasticsearch-outbound-firewall-{{ family }}-dns-{{ protocol }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: {{ protocol }}
        - dport: 53
        - destination: system_dns
        - match:
            - comment
            - owner
        - comment: 'elasticsearch: Allow outgoing DNS'
        - uid-owner: elasticsearch
        - jump: ACCEPT
        - require:
            - pkg: elasticsearch
{% endfor %}


elasticsearch-outbound-firewall-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - protocol: tcp
        - dport: 9300
        - match:
            - comment
            - owner
        - comment: 'elasticsearch: Allow outgoing traffic for internal comms'
        - uid-owner: elasticsearch
        - jump: ACCEPT
        - require:
            - pkg: elasticsearch


elasticsearch-inbound-firewall-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - dports: 9200,9300
        - match:
            - comment
        - comment: 'elasticsearch: Allow incoming traffic for http and internal comms'
        - jump: ACCEPT
{% endfor %}
