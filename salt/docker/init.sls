{% set docker = pillar.get('docker', {}) %}


include:
    - apt-transport-https


docker:
    pkg.installed:
        - name: docker.io

    file.managed:
        - name: /etc/docker/daemon.json
        - contents: '{{ docker | json }}'

    service.running:
        - name: docker
        - watch:
            - file: docker
            - cmd: docker-service-override


docker-service-override-dir:
    file.directory:
        - name: /etc/systemd/system/docker.service.d


docker-service-override:
    file.managed:
        - name: /etc/systemd/system/docker.service.d/override.conf
        - source: salt://docker/override.conf
        - require:
            - file: docker-service-override-dir
            - pkg: docker

    cmd.watch:
        - name: systemctl daemon-reload
        - watch:
            - file: docker-service-override


{% for host in docker.get('hosts', []) %}
{% if host.split(':')[0] == 'tcp' %}
docker-firewall-inbound-tcp-{{ host }}:
    firewall.append:
        - chain: INPUT
        - protocol: tcp
        {% set bind_host = host.split(':')[1].strip('/') %}
        - destination: {{ bind_host + '/0' if bind_host == '0.0.0.0' else bind_host }}
        - dport: {{ host.split(':')[2] }}
        - match:
            - comment
        - comment: 'docker: Allow {{ host }}'
        - jump: ACCEPT
{% endif %}
{% endfor %}
