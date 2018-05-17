PostgreSQL
==========

Installs postgres server or client.


How do I upgrade the server version?
------------------------------------

Ensure both the new and old version is installed (use the pillar `postgres:version` to ensure the new version is installed). Run the following on the server:

    #!/bin/sh

    set -eux

    if [ $# -ne 2]; then
        echo "usage: ./upgrade_postgres.sh <old-version> <new-version>" >&2
        exit 1
    fi

    export OLD_VERSION=$1
    export NEW_VERSION=$2

    sudo ln -s /etc/postgresql/$NEW_VERSION/main/postgresql.conf /var/lib/postgresql/$NEW_VERSION/main/postgresql.conf
    sudo ln -s /etc/postgresql/$OLD_VERSION/main/postgresql.conf /var/lib/postgresql/$OLD_VERSION/main/postgresql.conf

    trap "sudo rm -f /var/lib/postgresql/$NEW_VERSION/main/postgresql.conf /var/lib/postgresql/$OLD_VERSION/main/postgresql.conf" INT TERM EXIT

    sudo service postgresql@$OLD_VERSION-main stop
    sudo -iu postgres /usr/lib/postgresql/$NEW_VERSION/bin/pg_upgrade -d /var/lib/postgresql/$OLD_VERSION/main -D /var/lib/postgresql/$NEW_VERSION/main -b /usr/lib/postgresql/$OLD_VERSION/bin -B /usr/lib/postgresql/$NEW_VERSION/bin
    sudo service postgresql@NEW_VERSION-main start
