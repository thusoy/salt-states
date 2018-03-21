{% for user, config in pillar.get('iam', {}).items() %}
iam-{{ user }}:
    file.managed:
        - name: ~{{ user }}/.aws/credentials
        - source: salt://iam/files/credentials
        - template: jinja
        - context:
            id: {{ config.id }}
            secret: {{ config.secret }}
        - makedirs: True
        - show_changes: False
        - mode: 400
        - user: {{ user }}
        - group: {{ user }}
{% endfor %}
