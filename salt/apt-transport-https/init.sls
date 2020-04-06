{% if grains['osmajorrelease']|int < 10 %}
apt-transport-https:
    pkg.installed
{% endif %}
