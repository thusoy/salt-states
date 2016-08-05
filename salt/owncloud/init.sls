{% from 'macros.jinja' import nginx_site_pillar %}

{% set owncloud = pillar.get('owncloud', {}) %}
{% set version = owncloud.get('version', '8.2.7') %}
{% set hostname = owncloud.site_name %}
{% set admin_user = owncloud.get('admin_user', 'admin') %}
{% set admin_pass = owncloud.get('admin_pass') %}
{% set writeable_dirs = ['apps', 'config', 'data'] %}
{% set pillar_cert = 'owncloud:web_cert' if 'web_cert' in owncloud else 'nginx:default_cert' %}
{% set pillar_key = 'owncloud:web_key' if 'web_key' in owncloud else 'nginx:default_key' %}

{{ nginx_site_pillar(
  hostname,
  "salt://owncloud/nginx/nginx_site",
  pillar_cert,
  pillar_key) }}


include:
    - cronic
    - nginx
    - postgres.client


# Add nginx user to phpworker group
nginx-phpworker-group:
    cmd.run:
        - name: usermod -a -G phpworker nginx
        - unless: grep phpworker:.*:nginx /etc/group
        - require:
            - user: owncloud-php5-fpm
        - watch_in:
            - service: nginx


owncloud-php5-fpm:
    pkg.installed:
        - name: php5-fpm

    file.managed:
        - name: /etc/php5/fpm/pool.d/www.conf
        - source: salt://owncloud/php5-fpm-config
        - require:
            - pkg: php5-fpm

    service.running:
        - name: php5-fpm
        - require:
            - user: owncloud-php5-fpm
        - watch:
            - file: owncloud-php5-fpm

    user.present:
        - name: phpworker
        - fullname: PHP5 FPM worker
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin


owncloud-php-ini:
    file.managed:
        - name: /etc/php5/fpm/php.ini
        - source: salt://owncloud/php.ini
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - require:
            - pkg: owncloud-php5-fpm
        - watch_in:
            - service: owncloud-php5-fpm


owncloud-deps:
    pkg.installed:
        - pkgs:
            - libreoffice-common
            - libreoffice-writer
            - openjdk-7-jre
            - php5-cli
            - php5-common
            - php5-curl
            - php5-gd
            - php5-imagick
            - php5-intl
            - php5-json
            - php5-mcrypt
            - php5-pgsql


owncloud:
    postgres_user.present:
        - name: owncloud
        - password: "{{ salt['pillar.get']('owncloud:db_password') }}"
        - refresh_password: True
        - require:
            - pkg: postgresql-client

    postgres_database.present:
        - name: owncloud
        - owner: owncloud
        - user: postgres
        - require:
            - postgres_user: owncloud

    cron.present:
        - name: cronic php -f /srv/owncloud/cron.php
        - user: phpworker
        - identifier: owncloud-cron
        - minute: "*/15"

    cmd.run:
        - name: curl -s -o owncloud.tar.bz2 https://download.owncloud.org/community/owncloud-{{ version }}.tar.bz2 &&
                sha1sum owncloud.tar.bz2 > owncloud-{{ version }}.tar.bz2.sha1 &&
                tar xf owncloud.tar.bz2 -C /srv/ &&
                find /srv/owncloud{% for writeable_dir in writeable_dirs %} ! -wholename "/srv/owncloud/{{ writeable_dir }}*"{% endfor %} -print0 | xargs -0 chown root:root &&
                find /srv/owncloud -type f{% for writeable_dir in writeable_dirs %} ! -wholename "/srv/owncloud/{{ writeable_dir }}*"{% endfor %} -print0 | xargs -0 chmod 644 &&
                find /srv/owncloud -type d{% for writeable_dir in writeable_dirs %} ! -wholename "/srv/owncloud/{{ writeable_dir }}*"{% endfor %} -print0 | xargs -0 chmod 755
        - cwd: /usr/local/src
        - unless: sha1sum -c owncloud-{{ version }}.tar.bz2.sha1

    file.managed:
        - name: /srv/owncloud/config/autoconfig.php
        - source: salt://owncloud/autoconfig.php
        - template: jinja
        - context:
            {% if salt['pillar.get']('postgres.host') %}
            db_host: {{ salt['pillar.get']('postgres.host') }}
            {% else %}
            db_host: ''
            {% endif %}
            db_pass: {{ salt['pillar.get']('owncloud:db_password') }}
            admin_user: {{ admin_user }}
            {% if admin_pass %}
            admin_pass: {{ admin_pass }}
            {% endif %}
            directory: {{ salt['pillar.get']('owncloud:directory', '/srv/owncloud/data') }}
        - unless: test -f /srv/owncloud/config/config.php
        - user: root
        - group: phpworker
        - mode: 640


{% for writeable_dir in writeable_dirs %}
owncloud-{{ writeable_dir }}-directory:
    file.directory:
        - name: /srv/owncloud/{{ writeable_dir }}
        - user: phpworker
        - group: phpworker
        - recurse:
            - user
            - group
        - file_mode: 640
        - dir_mode: 750
        - watch:
            - cmd: owncloud
{% endfor %}


# Ensure that the tmp dir exists and is writeable if specified
# Necessary since otherwise php would use system tmp, which is often
# mapped to memory and thus will choke entirely on big uploads
{% if 'upload_tmp_dir' in owncloud %}
owncloud-upload-tmp-dir:
    file.directory:
        - name: {{ owncloud.upload_tmp_dir }}
        - user: root
        - group: phpworker
        - mode: 770
{% endif %}
