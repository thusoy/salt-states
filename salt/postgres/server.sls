{% set version = pillar.get('postgres.version', '9.4') -%}

postgresql-server:
  pkg.installed:
    - name: postgresql-{{ version }}

  file.managed:
    - name: /etc/postgresql/{{ version }}/main/pg_hba.conf
    - source: salt://postgres/pg_hba.conf
    - user: postgres
    - group: postgres
    - mode: 640
    - require:
      - pkg: postgresql-server

  service.running:
    - name: postgresql
    - require:
      - pkg: postgresql-server
    - watch:
      - file: postgresql-server


# Create on-disk dumps of the postgres db so that it can be backed up by other utilities
# (the on-disk pg format is not reliable for backup unless you can take atomic snapshots,
# which we can't guarantee unless we're using btrfs or zfs to do the backup)
postgresql-server-backups:
    file.directory:
        - name: /var/backups/postgres
        - user: root
        - group: postgres
        - mode: 775

    cron.present:
        - name: cronic sh -c 'cd /tmp; sudo -u postgres pg_dumpall | gzip > /var/backups/postgres/dump.sql.gz'
        - identifier: postgresql-server-backups
        - minute: random
        - hour: 1
