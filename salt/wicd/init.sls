{% set wicd = pillar.get('wicd', {}) %}
{% set client = wicd.get('client', 'gtk') %}

wicd:
    pkg.installed:
        - pkgs:
            - wicd
            - wicd-{{ client }}
