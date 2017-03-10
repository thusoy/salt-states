{% set cron = pillar.get('cron', {}) %}
{% set mailto = cron.get('mailto') %}

include:
    - .pillar_check


cron-mailto:
    cron.env_present:
        - name: MAILTO
        - value: {{ mailto }}
