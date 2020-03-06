{% set salt_master = pillar.get('salt_master', {}) %}
{% set extra_config = salt_master.get('extra_config', {}) %}

include:
    - .

{% for name, properties in extra_config.items() %}
salt-master-extra-config-{{ name }}:
    file.managed:
        - name: /etc/salt/master.d/{{ name }}.conf
        - user: root
        # - group: saltmaster
        - mode: 640
        - show_changes: False
        - template: jinja
        - source: salt://salt-master/config-yaml
        - context:
            config_pillar: salt_master:extra_config:{{ name }}
        - watch_in:
            - service: salt-master
{% endfor %}
