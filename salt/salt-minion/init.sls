{% from 'salt-minion/map.jinja' import salt_minion with context %}


include:
    - cronic


# Saltstack has a number of deprecation warnings on python 3.7 which is used
# on buster, thus need to silence warnings until these are fixed.
# Ref. https://github.com/saltstack/salt/issues/50911
# Ref. https://github.com/saltstack/salt/issues/52120
{% set log_level = 'warning' %}
{% if grains['os_family'] == 'Debian' and grains['osmajorrelease']|int >= 10 %}
{% set log_level = 'error' %}

# Ref. https://github.com/saltstack/salt/issues/54759
salt-minion-tornado:
    pkg.installed:
        - name: python3-tornado
{% endif %}


salt-minion-apply-cron:
    cron.present:
        - name: cronic salt-call state.apply --log-level {{ log_level }} --state-verbose False
        - identifier: salt-highstate
        {% for property in ('minute', 'hour', 'daymonth', 'month', 'dayweek') %}
        {% if property in salt_minion.apply_schedule %}
        - {{ property }}: '{{ salt_minion.apply_schedule.get(property) }}'
        {% endif %}
        {% endfor %}


{% for family in ('ipv4', 'ipv6') %}
salt-minion-firewall-allow-outgoing-to-master-{{ family }}:
    firewall.append:
        - chain: OUTPUT
        - family: {{ family }}
        - table: filter
        - match:
            - comment
            - owner
        - comment: 'salt.minion: Allow connecting to salt master'
        - uid-owner: root
        - proto: tcp
        - dports: 4505,4506
        - jump: ACCEPT
{% endfor %}
