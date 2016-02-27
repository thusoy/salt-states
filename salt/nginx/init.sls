{% set nginx = pillar.get('nginx', {}) %}
{% set install_from_source = nginx.get('install_from_source', True) %}


nginx-systemuser:
    user.present:
        - name: nginx
        - fullname: nginx worker
        - system: True
        - createhome: False
        - shell: /usr/sbin/nologin
        - groups:
            - shadow
        - optional_groups:
            - phpworker


include:
{% if install_from_source %}
    - nginx.source
{% else %}
    - nginx.package
{% endif %}
{% if nginx.get('dump_to_s3', False) %}
    - s3-uploader
{% endif %}


nginx-conf:
    file.managed:
        - name: /etc/nginx/nginx.conf
        - source: salt://nginx/nginx.conf
        - template: jinja
        - mode: 640
        - user: root
        - group: nginx
        - require:
            {% if install_from_source %}
            - cmd: nginx
            {% else %}
            - pkg: nginx
            {% endif %}
            - user: nginx-systemuser
        - watch_in:
            - service: nginx


nginx-pam-auth:
    file.managed:
        - name: /etc/pam.d/nginx
        - contents: "@include common-auth"


nginx-dh-param-default:
    file.symlink:
        - name: /etc/nginx/ssl/dhparam.pem
        - target: /etc/nginx/ssl/dhparam.{{ nginx.get('dh_keysize', 4096 ) }}.pem
        - force: True
        - require:
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx

{% for size in (1024, 2048, 4096) %}
nginx-dh-param-{{ size }}:
    cmd.run:
        - name: openssl dhparam -dsaparam -out /etc/nginx/ssl/dhparam.{{ size }}.pem {{ size }}
        - unless: openssl dhparam -noout -text -in /etc/nginx/ssl/dhparam.{{ size }}.pem | head -1 | grep {{ size }}
        - require:
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx
{% endfor %}


nginx-certificates-dir:
    file.directory:
        - name: /etc/nginx/ssl
        - user: root
        - group: nginx
        - file_mode: 755
        - require:
            - file: nginx-conf
            - user: nginx-systemuser


nginx-private-dir:
    file.directory:
        - name: /etc/nginx/private
        - user: root
        - group: nginx
        - mode: 750
        - require:
            - file: nginx-conf
            - user: nginx-systemuser


nginx-params:
    file.recurse:
        - name: /etc/nginx
        - source: salt://nginx/conf.d


# Disable defaults
{% set default_files = (
    'fastcgi.conf',
    'fastcgi_params',
    'mime.types',
    'nginx.conf',
    'scgi_params',
    'uwsgi_params',
) %}
nginx-defaults:
    file.absent:
        - names:
            - /etc/nginx/sites-enabled/default
            {% for default_file in default_files %}
            - /etc/nginx/{{ default_file }}.default
            {% endfor %}


nginx-www-certificate:
    file.managed:
        - name: /etc/nginx/ssl/www.thusoy.com.crt
        - contents_pillar: nginx:default_cert
        - require:
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx


{% for config_file in (
    'mime.types',
    'fastcgi_params',
    ) %}
nginx-config-file-{{ config_file }}:
    file.managed:
        - name: /etc/nginx/{{ config_file}}
        - source: salt://nginx/{{ config_file }}
        - watch_in:
            - service: nginx
{% endfor %}


nginx-www-key:
    file.managed:
        - name: /etc/nginx/private/www.thusoy.com.key
        - contents_pillar: nginx:default_key
        - user: root
        - group: nginx
        - show_diff: False
        - mode: 640
        - require:
            - user: nginx-systemuser
            - file: nginx-private-dir
        - watch_in:
            - service: nginx


nginx-sites-enabled:
    file.directory:
        - name: /etc/nginx/sites-enabled
        - user: root
        - group: nginx
        - mode: 755
        - require:
            - file: nginx-conf
            - user: nginx-systemuser


{% for family in ('ipv4', 'ipv6') %}
nginx-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        - family: {{ family }}
        - proto: tcp
        - match: comment
        - dports: 80,443
        - comment: "nginx: Allow incoming HTTP(S)"
        - jump: ACCEPT


{% for owner in ('root', 'nginx') %}
nginx-firewall-outgoing-{{ family }}-{{ owner }}:
    firewall.append:
        - table: filter
        - chain: OUTPUT
        - family: {{ family }}
        - proto: tcp
        - sports: 80,443
        - match:
            - comment
            - owner
            - state
        - comment: "nginx: Allow replying to HTTP(S) for {{ owner }}"
        - uid-owner: {{ owner }}
        - connstate: ESTABLISHED
        - jump: ACCEPT
{% endfor %}
{% endfor %}


nginx-log-dir:
    file.directory:
        - name: /var/log/nginx
        - require_in:
            - service: nginx


nginx-logrotate-config:
    file.managed:
        - name: /etc/logrotate.d/nginx
        - source: salt://nginx/logrotate.conf
        - template: jinja
