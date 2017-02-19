{% from 'nginx/map.jinja' import nginx with context %}


include:
    - .pillar_check
{% if nginx.get('dump_to_s3', False) %}
    - s3-uploader
{% endif %}


nginx-deps:
    pkg.installed:
        - pkgs:
            - apt-transport-https
            - ca-certificates


# Install ca-certificates to let nginx verify upstream certificates
nginx-ca-certificates:
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
            - file: nginx-certificates-dir
        - watch_in:
            - service: nginx


nginx:
    # The nginx user is created by the packages, but ensure that it has access to
    # shadow files to enable pam auth, and optionally php
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

    {% if nginx.repo %}
    pkgrepo.managed:
        - name: {{ nginx.repo }}
        - key_url: {{ nginx.repo_key_url }}
        - require_in:
            - pkg: nginx
    {% endif %}

    pkg.installed:
        - name: {{ nginx.package }}

    file.managed:
        - name: /etc/nginx/nginx.conf
        - source: salt://nginx/nginx.conf
        - template: jinja
        - mode: 644
        - user: root
        - group: nginx
        - context:
            keepalive_timeout: {{ nginx.keepalive_timeout }}
            log_formats:
                {% for log_format, format in nginx.log_formats.items() %}
                {{ log_format }}: '{{ format }}'
                {% endfor %}
            log_files:
                {% for log_file, format in nginx.log_files.items() %}
                {{ log_file }}: '{{ format }}'
                {% endfor %}
            extra_http:
                {% for extra_http_dict in nginx.extra_http %}
                {% for key, value in extra_http_dict.items() %}
                - {{ key }}: '{{ value }}'
                {% endfor %}
                {% endfor %}
        - require:
            - pkg: nginx
            - user: nginx

    service.running:
        - watch:
            - file: nginx


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
            - file: nginx
            - user: nginx


nginx-private-dir:
    file.directory:
        - name: /etc/nginx/private
        - user: root
        - group: nginx
        - mode: 750
        - require:
            - file: nginx
            - user: nginx


nginx-params:
    file.recurse:
        - name: /etc/nginx
        - source: salt://nginx/conf.d
        - template: jinja
        - require:
            - pkg: nginx
        - watch_in:
            - service: nginx


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
        - require_in:
            - service: nginx


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
        - show_changes: False
        - mode: 640
        - require:
            - user: nginx
            - file: nginx-private-dir
        - watch_in:
            - service: nginx


{% for family in ('ipv4', 'ipv6') %}
nginx-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - chain: INPUT
        {% if family == 'ipv4' and 'allow_sources_v4' in nginx %}
        - source: {{ ','.join(nginx.allow_sources_v4) }}
        {% elif family == 'ipv6' and 'allow_sources_v6' in nginx %}
        - source: {{ ','.join(nginx.allow_sources_v6) }}
        {% endif %}
        - family: {{ family }}
        - proto: tcp
        - dports: {{ '80,' if nginx['allow_plaintext'] else '' }}443
        - match:
            - comment
        - comment: "nginx: Allow incoming HTTP(S)"
        - jump: ACCEPT
{% endfor %}


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
