{% set timezone = pillar.get('timezone', 'UTC') %}

timezone:
    timezone.system:
        - name: {{ timezone }}
