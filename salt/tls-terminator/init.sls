{% from 'macros.jinja' import nginx_site %}
{% set sites = pillar.get('tls-terminator', {}) %}

include:
    - .pillar_check
    - nginx


{% for site, values in sites.items() %}

tls-terminator-timeout-page-{{ site }}:
    file.managed:
        - name: /usr/local/nginx/html/504-{{ site }}.html
        - source: salt://tls-terminator/nginx/504.html
        - makedirs: True
        - template: jinja
        - context:
            site: "{{ site }}"


{% set site_specific_cert = 'tls-terminator:' + site + ':cert' %}
{% set site_specific_key = 'tls-terminator:' + site + ':key' %}
{% set cert = site_specific_cert if salt['pillar.get'](site_specific_cert) else 'nginx:default_cert' %}
{% set key = site_specific_key if salt['pillar.get'](site_specific_key) else 'nginx:default_key' %}
{% set backend_protocol = 'https' if values.backend.startswith('https://') else 'http' %}
{% set backend_without_protocol = values.backend.split('://')[1] %}
{% if 'proxy_ca' in values %}
tls-terminator-upstream-ca-for-{{ site }}:
    file.managed:
        - name: /etc/nginx/ssl/upstream-ca-{{ site }}.pem
        - contents_pillar: tls-terminator:{{ site }}:proxy_ca


{% endif %}

{% if backend_without_protocol.find(':') != -1 %}
    {% set backend_port = backend_without_protocol.split(':')[1] %}
    {% set backend_without_protocol = backend_without_protocol.split(':')[0] %}
{% else %}
    {% set backend_port = 443 if backend_protocol == 'https' else 80 %}
{% endif %}

{% if 'proxy_auth' in values %}
tls-terminator-proxy-auth-for-{{ site }}-key:
    file.managed:
        - name: /etc/nginx/private/proxy-auth-for-{{ backend_without_protocol }}.key
        - contents_pillar: tls-terminator:{{ site }}:proxy_auth:key
        - user: root
        - group: nginx
        - mode: 640
        - show_diff: False

tls-terminator-proxy-auth-for-{{ site }}-cert:
    file.managed:
        - name: /etc/nginx/ssl/proxy-auth-for-{{ backend_without_protocol }}.crt
        - contents_pillar: tls-terminator:{{ site }}:proxy_auth:cert

{% endif %}

{% if 'proxy_ca_crl' in values %}
tls-terminator-proxy-ca-crl-for-{{ site }}:
    file.managed:
        - name: /etc/nginx/ssl/proxy-crl-for-{{ backend_without_protocol }}.pem
        - contents_pillar: tls-terminator:{{ site }}:proxy_ca_crl
{% endif %}
{{ nginx_site(
    site,
    'salt://tls-terminator/nginx/site',
    cert,
    key,
    {
        'backend': backend_without_protocol,
        'backend_protocol': backend_protocol,
        'backend_port': backend_port,
        'upstream_ca': 'ssl/upstream-ca-' + site + '.pem',
        'proxy_auth_cert': 'ssl/proxy-auth-for-' + backend_without_protocol + '.crt',
        'proxy_auth_key': 'private/proxy-auth-for-' + backend_without_protocol + '.key',
        'proxy_ca_crl': 'ssl/proxy-crl-for-' + backend_without_protocol + '.pem',
    }
) }}

{% endfor %}
