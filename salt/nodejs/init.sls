{% set node = pillar.get('node', {}) %}
{% set major_version = node.get('major_version', '8.x') %}

nodejs-deps:
    pkg.installed:
        - name: apt-transport-https

    pkgrepo.managed:
        - name: deb https://deb.nodesource.com/node_{{ major_version }} {{ grains['oscodename'] }} main
        - key_url: salt://nodejs/nodesource-release-key.asc
        - require:
            - pkg: nodejs-deps


nodejs:
    pkg.installed:
        - require:
            - pkgrepo: nodejs-deps
