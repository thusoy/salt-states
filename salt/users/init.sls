{% for name, user in pillar.get('users', {}).items() %}

{% for group in user.get('groups', []) %}
{{ name }}_{{ group }}_group:
    group.present:
        - name: {{ group }}
{% endfor %}

{{ name }}_user:
    user.present:
        - name: {{ name }}
        - shell: {{ user.get('shell', '/bin/bash') }}
        {% if 'password' in user -%}
        - password: {{ user['password'] }}
        {% endif -%}
        {% if 'uid' in user -%}
        - uid: {{ user['uid'] }}
        {% endif %}
        {% if 'gid' in user -%}
        - gid: {{ user['gid'] }}
        {% endif %}
        - gid_from_name: True
        {% if 'fullname' in user %}
        - fullname: {{ user['fullname'] }}
        {% endif -%}
        - optional_groups:
            {% for group in user.get('optional_groups', []) %}
            - {{ group }}
            {% endfor %}
        - groups:
            {% for group in user.get('groups', []) -%}
            - {{ group }}
            {% endfor %}
        {% if user.get('groups') %}
        - require:
            {% for group in user.get('groups', []) -%}
            - group: {{ group }}
            {% endfor %}
        {% endif %}

    {% if 'ssh_auth' in user %}
    ssh_auth.present:
        - user: {{ name }}
        - names:
            {% for auth in user['ssh_auth'] %}
                - {{ auth }}
            {% endfor %}
        # Specify fingerprint hash type to avoid logspam on 2016.11, even though it's unused
        - fingerprint_hash_type: sha256
        - require:
            - user: {{ name }}_user
    {% endif %}

{% if 'ssh_auth.absent' in user %}
{% for auth in user['ssh_auth.absent'] %}
ssh_auth_delete_{{ name }}_{{ loop.index0 }}:
    ssh_auth.absent:
        - user: {{ name }}
        - name: {{ auth }}
        # Specify fingerprint hash type to avoid logspam on 2016.11, even though it's unused
        - fingerprint_hash_type: sha256
        - require:
            - user: {{ name }}_user
{% endfor %}
{% endif %}

{% endfor %}


{% for user in pillar.get('absent_users', []) %}
absent-user-{{ user }}:
    user.absent:
        - name: {{ user }}
        - purge: True
        - force: True
{% endfor %}


{% for group in pillar.get('absent_groups', []) %}
absent-group-{{ group }}:
    group.absent:
        - name: {{ group }}
{% endfor %}


bash-profile:
    file.managed:
        - name: /etc/profile
        - source: salt://users/profile
