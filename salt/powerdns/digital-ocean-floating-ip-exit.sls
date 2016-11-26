# Routes outgoing DNS traffic through a SNAT, use this if you want to exit from
# Digital Ocean Floating IP f. ex. Docs:
# https://www.digitalocean.com/community/tutorials/how-to-use-floating-ips-on-digitalocean
{% set powerdns = pillar.get('powerdns', {}) %}
{% set anchor_ip = grains.digitalocean.interfaces.public[0].anchor_ipv4.ip_address %}

{% if anchor_ip %}
{% for protocol in ('udp', 'tcp') %}
{% for replica in powerdns.get('allow_axfr_ips', []) %}
powerdns-digital-ocean-floating-ip-exit-{{ protocol }}-{{ replica }}:
    firewall.append:
        - table: nat
        - chain: POSTROUTING
        - protocol: {{ protocol }}
        - match:
            - comment
        - comment: 'powerdns: Exit to DNS replicas through Floating IP'
        - dport: 53
        - destination: {{ anchor_ip }}
        - out-interface: eth0
        - jump: SNAT
        - to-source: {{ replica }}
{% endfor %}
{% endfor %}
{% endif %}
