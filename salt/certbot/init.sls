{% set certbot = pillar.get('certbot', {}) %}

include:
    - .pillar_check

{% set needs_backport = grains.get('oscodename') == 'jessie' %}
certbot:
    {% if needs_backport %}
    pkgrepo.managed:
        - name: deb http://ftp.debian.org/debian {{ grains.get('oscodename') }}-backports main
    {% endif %}

    pkg.installed:
        {% if needs_backport %}
        - fromrepo: jessie-backports
        - require:
            - pkgrepo: certbot
        {% endif %}


{% for site in certbot.get('sites', []) %}
certbot-update-{{ site }}:
    cron.present:
        - name: certbot certonly
                --standalone
                {% if 'pre_hook' in certbot -%}
                --pre-hook '{{ certbot.pre_hook }}'
                {% endif -%}
                {% if 'post_hook' in certbot -%}
                --post-hook '{{ certbot.post_hook }}'
                {% endif -%}
                --domain {{ site }}
                --quiet
                --email {{ certbot.administrative_contact }}
                --agree-tos
                --text
        - identifier: certbot-update-{{ site }}
        - minute: random
{% endfor %}


{% for family in ('ipv4', 'ipv6') %}
certbot-firewall-outgoing-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
            - owner
        - comment: 'certbot: Allow outgoing https'
        - uid-owner: root
        - jump: ACCEPT


certbot-firewall-incoming-https-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: INPUT
        - protocol: tcp
        - dport: 443
        - match:
            - comment
        - comment: 'certbot: Allow incoming HTTPS'
        - jump: ACCEPT


{% for protocol in ('udp', 'tcp') %}
certbot-firewall-outgoing-dns-{{ protocol }}-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - protocol: {{ protocol }}
        - dport: 53
        - match:
            - comment
            - owner
        - comment: 'certbot: Allow outgoing DNS'
        - uid-owner: root
        - jump: ACCEPT
{% endfor %}
{% endfor %}
