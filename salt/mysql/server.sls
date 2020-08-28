{% from 'mysql/map.jinja' import mysql with context %}


mysql-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            # This is needed for salt to be able to manage databases, tables and users
            - python3-mysqldb


mysql:
    pkgrepo.managed:
        - name: deb https://repo.mysql.com/apt/debian {{ grains.oscodename }} mysql-{{ mysql.server.version }}
        - key_url: salt://mysql/release-key.asc
        - require:
            - pkg: mysql-deps

    pkg.installed:
        - name: mysql-community-server
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
