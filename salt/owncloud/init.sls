{% set owncloud = pillar.get('owncloud', {}) %}
{% set version = owncloud.get('version', '8.2.7') %}
{% set hostname = owncloud.site_name %}
{% set admin_user = owncloud.get('admin_user', 'admin') %}
{% set admin_pass = owncloud.get('admin_pass') %}
{% set writeable_dirs = ['apps', 'config', 'data'] %}
{% set pillar_cert = 'owncloud:web_cert' if 'web_cert' in owncloud else 'nginx:default_cert' %}
{% set pillar_key = 'owncloud:web_key' if 'web_key' in owncloud else 'nginx:default_key' %}

{% set default_php_version = '5' %}
{% if grains.os == 'Ubuntu' and grains.osmajorrelease > 16 %}
    {% set default_php_version = '7.0' %}
{% endif %}
{% set php_version = owncloud.get('php_version', default_php_version) %}

{% set openjdk_version = owncloud.get('openjdk_version', '8') %}
{% set acme = owncloud.get('acme', False) %}
{% set ssl_cert = '/etc/letsencrypt/live/' + hostname + '/fullchain.pem' if acme else 'ssl/' + hostname + '.crt' %}
{% set ssl_key = '/etc/letsencrypt/live/' + hostname + '/privkey.pem' if acme else 'private/' + hostname + '.key' %}


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
            - user: owncloud-php-fpm
        - watch_in:
            - service: nginx


owncloud-php-fpm:
    file.managed:
        {% if php_version == '5' %}
        - name: /etc/php{{ php_version }}/fpm/pool.d/www.conf
        {% else %}
        - name: /etc/php/{{ php_version }}/fpm/pool.d/www.conf
        {% endif %}
        - source: salt://owncloud/php-fpm-config
        - makedirs: True
        - template: jinja
        - context:
            php_version: {{ php_version }}
        - watch_in:
            - service: owncloud-php-fpm

    pkg.installed:
        - name: php{{ php_version }}-fpm
        # Ensure the config file exists first since otherwise we'd try to start with
        # the non-existent www-data user
        - require:
            - file: owncloud-php-fpm

    service.running:
        - name: php{{ php_version }}-fpm
        - require:
            - user: owncloud-php-fpm
        - watch:
            - file: owncloud-php-fpm

    user.present:
        - name: phpworker
        - fullname: PHP{{ php_version }} FPM worker
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin


{% if php_version != '5' %}
owncloud-php-systemd-tmpfiles.d:
    file.managed:
        - name: /usr/lib/tmpfiles.d/php{{ php_version }}-fpm.conf
        - contents: |
            #Type Path        Mode UID      GID      Age Argument
                d /run/php    0755 phpworker phpworker -   -
{% endif %}


owncloud-php-ini:
    file.managed:
        {% if php_version == '5' %}
        - name: /etc/php{{ php_version }}/fpm/php.ini
        {% else %}
        - name: /etc/php/{{ php_version }}/fpm/php.ini
        {% endif %}
        - source: salt://owncloud/php.ini
        - template: jinja
        - user: root
        - group: root
        - mode: 644
        - require:
            - pkg: owncloud-php-fpm
        - watch_in:
            - service: owncloud-php-fpm


owncloud-deps:
    pkg.installed:
        - pkgs:
            - libreoffice-common
            - libreoffice-writer
            - openjdk-{{ openjdk_version }}-jre
            - php{{ php_version }}-cli
            - php{{ php_version }}-common
            - php{{ php_version }}-curl
            - php{{ php_version }}-gd
            - php{{ php_version }}-intl
            - php{{ php_version }}-json
            - php{{ php_version }}-mcrypt
            - php{{ php_version }}-pgsql

            {% if php_version == '7.0' %}
            # The php7 package of imagick is named only php-imagick
            - php-imagick
            # Some other package apparently only needed under php 7.0
            - php{{ php_version }}-zip
            - php{{ php_version }}-xml
            - php{{ php_version }}-mbstring
            {%  else %}
            - php{{ php_version }}-imagick
            {% endif %}


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


owncloud-nginx-site:
    file.managed:
        - name: /etc/nginx/sites-enabled/{{ hostname }}
        - source: salt://owncloud/nginx/nginx_site
        - template: jinja
        - require:
            - pkg: nginx
        - watch_in:
            - service: nginx
        - context:
            server_name: {{ hostname }}
            php_version: php_version
            ssl_cert: ssl_cert
            ssl_key: ssl_key


{% if not acme %}
owncloud-nginx-cert:
    file.managed:
        - name: /etc/nginx/ssl/{{ hostname }}.crt
        - contents_pillar: {{ pillar_cert }}
        - require:
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx


owncloud-nginx-key:
    file.managed:
        - name: /etc/nginx/private/{{ hostname }}.key
        - contents_pillar: {{ pillar_key }}
        - user: root
        - group: nginx
        - mode: 640
        - show_changes: False
        - require:
            - file: nginx-private-dir
        - watch_in:
            - service: nginx
{% endif %}
