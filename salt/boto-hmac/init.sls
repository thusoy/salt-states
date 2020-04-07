{% set boto = pillar.get('boto') %}

boto-hmac:
    file.managed:
        - name: /root/.boto
        - source: salt://boto-hmac/config
        - user: root
        - group: root
        - mode: 640
        - show_changes: False
        - template: jinja
        - context:
            {% if 'access_key_id' in boto %}
            access_key_id: {{ boto.access_key_id }}
            {% else %}
            access_key_id: {{ salt['pillar.get'](boto.access_key_id_pillar) }}
            {% endif %}
            {% if 'secret_access_key' in boto %}
            secret_access_key: {{ boto.secret_access_key }}
            {% else %}
            secret_access_key: {{ salt['pillar.get'](boto.secret_access_key_pillar) }}
            {% endif %}
