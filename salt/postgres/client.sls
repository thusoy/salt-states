{% set version = pillar.get('postgres.version', '9.4') %}

postgresql-client:
  pkg.installed:
    - pkgs:
      - libpq-dev
      - postgresql-client-common
      - postgresql-client-{{ version }}
