# Since dynamically resolving DNS is only supported in the commercal version of
# nginx, regularly reload the config to ensure we never try an expired IP for
# too long. Note that reloads are graceful to existing connections and will
# gradually transition from old to new workers without any service disruption.

{% from 'nginx/map.jinja' import nginx with context %}
{% set regular_reload = nginx['regular_reload'] %}

nginx-regular-reload:
    cron.present:
        - name: service nginx reload
        - identifier: nginx-regular-reload
        {% if 'minute' in regular_reload %}
        - minute: '{{ regular_reload['minute'] }}'
        {% endif %}
        {% if 'hour' in regular_reload %}
        - hour: '{{ regular_reload['hour'] }}'
        {% endif %}
        {% if 'daymonth' in regular_reload %}
        - daymonth: '{{ regular_reload['daymonth'] }}'
        {% endif %}
        {% if 'month' in regular_reload %}
        - month: '{{ regular_reload['month'] }}'
        {% endif %}
        {% if 'dayweek' in regular_reload %}
        - dayweek: '{{ regular_reload['dayweek'] }}'
        {% endif %}
