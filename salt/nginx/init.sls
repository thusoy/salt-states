{% from 'nginx/map.jinja' import nginx %}

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
    - .pillar_check
{% if nginx.install_from_source %}
    - nginx.source
{% else %}
    - nginx.package
{% endif %}
{% if nginx.dump_to_s3 %}
    - s3-uploader
{% endif %}


# Install ca-certificates to let nginx verify upstream certificates
nginx-ca-certificates:
    pkg.installed:
        - name: ca-certificates

    cmd.run:
        - name: existing_digest=$(sha1sum /etc/nginx/ssl/all-certs.pem 2>/dev/null
                                  | cut -d" " -f1 || echo 'no existing file');
                new_digest=$(find /etc/ssl/certs/ -type f
                             | sort
                             | xargs cat
                             | sha1sum
                             | cut -d" " -f1);
                if [ "$new_digest" != "$existing_digest" ]; then
                    find /etc/ssl/certs/ -type f
                    | sort
                    | xargs cat
                    > /etc/nginx/ssl/all-certs.pem;
                    echo "changed=yes";
                fi
        - stateful: True
        - require:
            - pkg: nginx-ca-certificates
            - file: nginx-conf
        - watch_in:
            - service: nginx


nginx-conf:
    file.managed:
        - name: /etc/nginx/nginx.conf
        - source: salt://nginx/nginx.conf
        - template: jinja
        - mode: 640
        - user: root
        - group: nginx
        - require:
            {% if nginx.install_from_source %}
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
        - target: /etc/nginx/ssl/dhparam.{{ nginx.dh_keysize }}.pem
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


nginx-default-certificate:
    file.managed:
        - name: /etc/nginx/ssl/default.crt
        - contents_pillar: nginx:default_cert
        - require:
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx


nginx-default-key:
    file.managed:
        - name: /etc/nginx/private/default.key
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
        - dports: 80,443
        - match:
            - comment
        - comment: "nginx: Allow incoming HTTP(S)"
        - jump: ACCEPT
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


nginx-cache-dir:
    file.directory:
        - name: /var/cache/nginx
        - require_in:
            - service: nginx
        - user: nginx
        - group: nginx
        - mode: 775
