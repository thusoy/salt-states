postgres-regular-backup:
    cron.present:
        - name: cd /tmp; pg_dumpall | gzip > /var/backups/postgres/dump.sql.gz
        - user: postgres
        - identifier: postgresql-server-backups
        - minute: random
        - hour: 1
