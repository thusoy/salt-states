{% from 'postgres/map.jinja' import postgres %}
{% set postgis = pillar.get('postgis', {}) %}
{% set version = postgis.get('version', '2.3') %}


include:
    - postgres.server


postgis:
    pkg.installed:
        - name: postgresql-{{ postgres.version }}-postgis-{{ version }}
