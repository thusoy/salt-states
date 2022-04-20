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
