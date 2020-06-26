{% for name, user in pillar.get('users', {}).items() %}

{% for group in user.get('groups', []) %}
users-{{ name }}-group-{{ group }}:
    group.present:
        - name: {{ group }}
{% endfor %}

users-{{ name }}:
    group.present:
        - name: {{ name }}
        {% if 'gid' in user -%}
        - gid: {{ user['gid'] }}
        {% endif %}

    user.present:
        - name: {{ name }}
        - shell: {{ user.get('shell', '/bin/bash') }}
        {% if 'password' in user -%}
        - password: {{ user['password'] }}
        {% else %}
        - empty_password: True
        {% endif -%}
        {% if 'uid' in user -%}
        - uid: {{ user['uid'] }}
        {% endif %}
        {% if 'gid' in user -%}
        - gid: {{ user['gid'] }}
        {% endif %}
        {% if 'fullname' in user %}
        - fullname: {{ user['fullname'] }}
        {% endif -%}
        {% if grains.saltversioninfo > [3000] %}
        - usergroup: False
        {% else %}
        - gid_from_name: True
        {% endif %}
        - optional_groups:
            {% for group in user.get('optional-groups', []) %}
            - {{ group }}
            {% endfor %}
        - groups:
            {% for group in user.get('groups', []) -%}
            - {{ group }}
            {% endfor %}
        {% if user.get('groups') %}
        - require:
            - group: {{ name }}
            {% for group in user.get('groups', []) -%}
            - group: {{ group }}
            {% endfor %}
        {% endif %}

    {% if 'ssh-auth' in user %}
    ssh_auth.present:
        - user: {{ name }}
        - names:
            {% for auth in user['ssh-auth'] %}
                - {{ auth }}
            {% endfor %}
        # Specify fingerprint hash type to avoid logspam on 2016.11, even though it's unused
        - fingerprint_hash_type: sha256
        - require:
            - user: users-{{ name }}
    {% endif %}


{% for auth in user.get('ssh-auth.absent', []) %}
users-{{ name }}-ssh-auth-absent-{{ loop.index0 }}:
    ssh_auth.absent:
        - user: {{ name }}
        - name: {{ auth }}
        # Specify fingerprint hash type to avoid logspam on 2016.11, even though it's unused
        - fingerprint_hash_type: sha256
        - require:
            - user: users-{{ name }}
{% endfor %}

{% endfor %}


{% for user in pillar.get('users.absent', []) %}
users-absent-{{ user }}:
    user.absent:
        - name: {{ user }}
        - purge: True
        - force: True
{% endfor %}


{% for group in pillar.get('users.absent-groups', []) %}
users-absent-group-{{ group }}:
    group.absent:
        - name: {{ group }}
{% endfor %}


bash-profile:
    file.managed:
        - name: /etc/profile
        - source: salt://users/profile
