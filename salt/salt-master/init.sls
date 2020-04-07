# Note: This state is run masterless
{% set salt_master = pillar.get('salt_master', {}) %}

include:
    - .pillar_check


# We can restart the master safely here since we're running masterless
salt-master:
    file.managed:
        - name: /etc/salt/master
        {% if salt_master.get('master_config') is mapping %}
        - source: salt://salt-master/config-yaml
        - template: jinja
        - context:
            config_pillar: salt_master:master_config
        {% else %}
        - contents_pillar: salt_master:master_config
        {% endif %}

    service.running:
        - watch:
            - file: salt-master


# No long-running service to restart for this since the minion is
# masterless
salt-master-minion-config:
    file.managed:
        - name: /etc/salt/minion
        {% if salt_master.get('master_minion_config') is mapping %}
        - source: salt://salt-master/config-yaml
        - template: jinja
        - context:
            config_pillar: salt_master:master_minion_config
        {% else %}
        - contents_pillar: salt_master:master_minion_config
        {% endif %}
