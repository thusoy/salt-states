# Routes exiting traffic through a SNAT, use this if you want to exit from
# Digital Ocean Floating IP f. ex. Docs:
# https://www.digitalocean.com/community/tutorials/how-to-use-floating-ips-on-digitalocean
{% set iptables = pillar.get('iptables', {}) %}

{% if iptables.get('anchor-ip') %}
iptables-digital-ocean-floating-ip-exit:
    firewall.append:
        - table: nat
        - chain: POSTROUTING
        - protocol: all
        - out-interface: eth0
        - to-source: {{ iptables['anchor-ip'] }}
        - jump: SNAT
{% endif %}
