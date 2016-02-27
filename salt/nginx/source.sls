{% set nginx = pillar.get('nginx', {}) -%}
{% set version = nginx.get('version', '1.8.1') -%}
{% set checksum = nginx.get('checksum', 'sha256=8f4b3c630966c044ec72715754334d1fdf741caa1d5795fb4646c27d09f797b7') -%}
{% set home = nginx.get('home', '/usr/local/nginx') -%}
{% set source = nginx.get('source_root', '/usr/local/src') -%}

{% set nginx_package = source + '/nginx-' + version + '.tar.gz' -%}
{% set nginx_home     = home + "/nginx-" + version -%}

{% set more_headers_identifier = nginx.get('more_headers_identifier', '0.28 sha256=67e5ca6cd9472938333c4530ab8c8b8bc9fe910a8cb237e5e5f1853e14725580') %}
{% set more_headers_version, more_headers_hash = more_headers_identifier.split() %}

{% set pcre_version_identifier = nginx.get('pcre_version_identifier', '8.37 sha256=51679ea8006ce31379fb0860e46dd86665d864b5020fc9cd19e71260eef4789d') %}
{% set pcre_version, pcre_source_hash = pcre_version_identifier.split() %}

{% set pam_auth_version_identifier = nginx.get('pam_auth_version_identifier', '1.4 sha256=095742c5bcb86f2431e215db785bdeb238d594f085a0ac00d16125876a157409') %}
{% set pam_auth_version, pam_auth_source_hash = pam_auth_version_identifier.split() %}


get-nginx:
    pkg.installed:
        - names:
            - build-essential
            - checkinstall
            - libssl-dev
            - libpam0g-dev

    file.managed:
        - name: {{ nginx_package }}
        - source: http://nginx.org/download/nginx-{{ version }}.tar.gz
        - source_hash: {{ checksum }}

    cmd.wait:
        - cwd: {{ source }}
        - name: tar -zxf {{ nginx_package }} -C {{ home }}
        - require:
            - pkg: get-nginx
            - file: {{ home }}
        - watch:
            - file: get-nginx


get-pam-auth-module:
    file.managed:
        - name: {{ source }}/ngx_http_auth_pam_module-{{ pam_auth_version }}.tar.gz
        - source: https://github.com/stogh/ngx_http_auth_pam_module/archive/v{{ pam_auth_version }}.tar.gz
        - source_hash: {{ pam_auth_source_hash }}

    cmd.wait:
        - name: tar xf ngx_http_auth_pam_module-{{ pam_auth_version }}.tar.gz
        - cwd: {{ source }}
        - require:
            - file: nginx-home
        - watch:
            - file: get-pam-auth-module


get-more-headers-module:
    file.managed:
        - name: {{ source }}/headers-more-nginx-module-{{ more_headers_version }}.tar.gz
        - source: https://github.com/openresty/headers-more-nginx-module/archive/v{{ more_headers_version }}.tar.gz
        - source_hash: {{ more_headers_hash }}

    cmd.wait:
        - name: tar xf headers-more-nginx-module-{{ more_headers_version }}.tar.gz
        - cwd: {{ source }}
        - require:
            - file: nginx-home
        - watch:
            - file: get-more-headers-module


get-pcre-source:
    file.managed:
        - name: {{ source }}/pcre-{{ pcre_version }}.tar.bz2
        - source: http://downloads.sourceforge.net/sourceforge/pcre/pcre-{{ pcre_version }}.tar.bz2
        - source_hash: {{ pcre_source_hash }}

    cmd.wait:
        - name: tar xf pcre-{{ pcre_version }}.tar.bz2
        - cwd: {{ source }}
        - require:
            - file: nginx-home
        - watch:
            - file: get-pcre-source


nginx-home:
    file.directory:
        - name: {{ home }}
        - user: nginx
        - group: nginx
        - makedirs: True
        - mode: 0755
        - require:
            - user: nginx-systemuser


nginx:
    cmd.wait:
        - cwd: {{ nginx_home }}
        - name: ./configure --conf-path=/etc/nginx/nginx.conf
            --add-module={{ source }}/ngx_http_auth_pam_module-{{ pam_auth_version }}
            --add-module={{ source }}/headers-more-nginx-module-{{ more_headers_version }}
            --sbin-path=/usr/sbin/nginx
            --user=nginx
            --group=nginx
            --prefix=/usr/local/nginx
            --error-log-path=/var/log/nginx/error.log
            --pid-path=/var/run/nginx.pid
            --lock-path=/var/lock/nginx.lock
            --http-log-path=/var/log/nginx/access.log
            --http-client-body-temp-path={{ home }}/body
            --http-proxy-temp-path={{ home }}/proxy
            --http-fastcgi-temp-path={{ home }}/fastcgi
            --without-http_browser_module
            --without-http_empty_gif_module
            --without-http_scgi_module
            --without-http_split_clients_module
            --without-http_map_module
            --without-http_geo_module
            --without-http_userid_module
            --without-http_ssi_module
            --with-http_stub_status_module
            --with-pcre={{ source }}/pcre-{{ pcre_version }}
            --with-pcre-jit
            --with-ipv6
            --with-cc-opt='-g -O2 -fstack-protector-all --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2'
            --with-ld-opt='-Wl,-z,relro,-z,now -Wl,--as-needed'
            --with-http_ssl_module &&
            make -j{{ grains.num_cpus }} &&
            make install
        - watch:
            - cmd: get-nginx
            - cmd: get-pam-auth-module
            - cmd: get-more-headers-module
            - cmd: get-pcre-source
        - watch_in:
            - service: nginx

    init_script.managed:
        - systemd: salt://nginx/nginx-systemd
        - sysvinit: salt://nginx/nginx-sysvinit
        - upstart: salt://nginx/nginx-upstart

    service.running:
        - enable: True
        - require:
            - cmd: nginx
            - file: {{ home }}
            - file: nginx-certificates-dir
            - file: nginx-defaults
            - file: nginx-private-dir
            - file: nginx-sites-enabled
        - watch:
            - init_script: nginx
            - file: nginx-conf
            - file: nginx-params
