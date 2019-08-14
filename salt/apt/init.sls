{% set apt = pillar.get('apt', {}) %}

{% for repo in apt.get('repos', []) %}
apt-repo-{{ loop.index }}:
    pkgrepo.managed:
        - name: {{ repo }}
        - order: 1
{% endfor %}
