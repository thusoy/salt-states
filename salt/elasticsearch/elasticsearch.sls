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
    # TODO versioning
    pkg.installed:
        - pkgs:
            - elasticsearch
        - require:
            - pkgrepo: elasticsearch

    # start service and watch the config files for restarting the service
    service.running:
        - watch:
          - file: /etc/elasticsearch/elasticsearch.yml
          - file: /etc/elasticsearch/jvm.options

/etc/elasticsearch/jvm.options:
    file.managed:
        - source:
          - salt://elasticsearch/jvm.options

/etc/elasticsearch/elasticsearch.yml:
    file.managed:
        - source:
          - salt://elasticsearch/elasticsearch.yml
