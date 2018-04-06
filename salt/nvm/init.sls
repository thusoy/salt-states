{% set nvm = pillar.get('nvm', {}) %}
{% set version = nvm.get('version', 'v0.33.8') %}
{% set target_directory = nvm.get('target_directory') %}

include:
    - .pillar_check
    - git

nvm:
    git.latest:
        - name: https://git@github.com/creationix/nvm
        - rev: {{ version }}
        - target: {{ target_directory }}
