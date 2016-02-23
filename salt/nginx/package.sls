{% set ubuntu = grains['os'] == 'Ubuntu' -%}

nginx:
    {% if ubuntu %}
    pkgrepo.managed:
        - ppa: nginx/stable
    {% endif %}

    pkg:
        - latest
        {% if ubuntu %}
        - require:
            - pkgrepo: nginx
        {% endif %}

    service.running:
        - require:
            - file: nginx-certificates-dir
            - file: nginx-defaults
            - file: nginx-private-dir
            - file: nginx-sites-enabled
            - pkg: nginx
            - user: nginx-systemuser
        - watch:
            - file: nginx-conf
            - file: nginx-params
