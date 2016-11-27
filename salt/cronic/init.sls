# Cronic is a cron shell shim that will only send email upon failures
# Read more: http://habilis.net/cronic/

cron-path:
    cron.env_present:
        - name: PATH
        - value: /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin


cronic:
    file.managed:
        - name: /usr/bin/cronic
        - source: salt://cronic/cronic
        - mode: 755
