{% from 'timezone/map.jinja' import timezone with context %}

timezone:
    timezone.system:
        - name: {{ timezone }}
