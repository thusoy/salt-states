{% set docker = pillar.get('docker-ce', {}) %}


docker-ce-deps:
    pkg.installed:
        - name: apt-transport-https


docker-ce:
    pkgrepo.managed:
        - name: deb https://download.docker.com/linux/debian {{ grains['oscodename'] }} stable
        - key_url: salt://docker-ce/release-key.asc
        - require:
            - pkg: docker-ce-deps

    pkg.installed:
        - pkgs:
            - docker-ce
            - docker-ce-cli
        - require:
            - pkgrepo: docker-ce

    file.managed:
        - name: /etc/docker/daemon.json
        - contents: '{{ docker | json }}'

    service.running:
        - name: docker
        - watch:
            - file: docker-ce
