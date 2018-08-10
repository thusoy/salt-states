{% set version = pillar.get('postgres.version') %}

postgresql-client:
  pkg.installed:
    - pkgs:
      - libpq-dev
      - postgresql-client-common
      {% if version %}
      - postgresql-client-{{ version }}
      {% else %}
      - postgresql-client
      {% endif %}
