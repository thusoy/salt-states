{% set logrotate = pillar.get('logrotate', {}) %}
{% set schedule = logrotate.get('schedule', 'daily') %}

logrotate:
    pkg.installed: []

{% if schedule == 'hourly' %}
    cmd.run:
        - name: dpkg-divert --add --rename --divert /etc/cron.hourly/logrotate /etc/cron.daily/logrotate
        - onlyif: test -z "$(dpkg-divert --list /etc/cron.daily/logrotate)"
{% else %}
    cmd.run:
        - name: dpkg-divert --remove --rename /etc/cron.daily/logrotate
        - onlyif: test -n "$(dpkg-divert --list /etc/cron.daily/logrotate)"
{% endif %}
