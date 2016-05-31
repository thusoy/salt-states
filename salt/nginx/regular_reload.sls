# Since dynamically resolving DNS is only supported in the commercal version of
# nginx, regularly reload the config to ensure we never try an expired IP for
# too long. Note that reloads are graceful to existing connections and will
# gradually transition from old to new workers without any service disruption.

nginx-regular-reload:
    cron.present:
        - name: service nginx reload
        - identifier: nginx-regular-reload
        - minute: random
