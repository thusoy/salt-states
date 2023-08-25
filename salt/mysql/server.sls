{% from 'mysql/map.jinja' import mysql with context %}


include:
    - apt-transport-https


mysql:
    pkgrepo.managed:
        - name: deb https://repo.mysql.com/apt/debian {{ grains.oscodename }} mysql-{{ mysql.server.version }}
        - key_url: salt://mysql/release-key.asc

    pkg.installed:
        - name: mysql-community-server
        - version: '>={{ mysql.server.version }}'
        - require:
            - pkgrepo: mysql

    file.managed:
        - name: /etc/mysql/conf.d/mysqld.cnf
        - source: salt://mysql/mysqld.cnf
        - template: jinja
        - require:
            - pkg: mysql

    service.running:
        - watch:
            - file: mysql
            - pkg: mysql


mysql-builtin-client:
    pkg.purged:
        - name: python3-mysqldb


mysql-client:
    # This is needed for salt to be able to manage databases, tables and users. The default
    # installation of python3-mysqldb is built on mariadb and isn't able to connect to mysql 8
    # without connection errors (error 1156: Got packets out of order)
    pkg.installed:
        - pkgs:
            - libmysqlclient-dev
            - python3-pip
        - require:
            - pkg: mysql-builtin-client
            - pkgrepo: mysql

    pip.installed:
        - name: mysqlclient==2.1.1
        - require:
            - pkg: mysql-client
            - pkg: mysql


{% for family in ('ipv4', 'ipv6') %}
mysql-firewall-inbound-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - dport: 3306
        - match:
            - comment
        - comment: 'mysql.server: Allow inbound connections'
        - jump: ACCEPT
{% endfor %}
