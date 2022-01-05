{% if grains['osmajorrelease']|int < 10 %}
apt-transport-https:
    pkg.installed
{% else %}
apt-transport-https:
    test.nop
{% endif %}
