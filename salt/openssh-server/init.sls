{% from 'openssh-server/map.jinja' import openssh_server with context %}
{% set minumum_modulus_size = openssh_server.minumum_modulus_size %}


openssh-server:
    pkg.installed:
        - name: openssh-server

    service.running:
        - name: ssh
        - watch:
            - file: openssh-server

    file.managed:
        - name: /etc/ssh/sshd_config
        - source: salt://openssh-server/sshd_config
        - template: jinja
        - require:
            - pkg: openssh-server


# Delete ssh moduli weaker than 2048 bits
openssh-server-moduli:
    cmd.run:
        - name: |
            if [ -n "$(awk '$5 >= {{ minumum_modulus_size }}' /etc/ssh/moduli | tail -n +2)" ]; then
                echo "Removing weak ssh moduli"
                awk '$5 >= {{ minumum_modulus_size }}' /etc/ssh/moduli > /tmp/strong-ssh-moduli
                mv /tmp/strong-ssh-moduli /etc/ssh/moduli
            else
                echo "Generating strong SSH moduli..."
                ssh-keygen -G /tmp/strong-ssh-moduli -b 4096
                ssh-keygen -T /etc/ssh/moduli -f /tmp/strong-ssh-moduli
                rm /tmp/strong-ssh-moduli
            fi
        - onlyif: "tail -n +2 /etc/ssh/moduli | awk '$5 < {{ minumum_modulus_size }}' | head -1 | grep -q ^"
        - watch_in:
            - service: openssh-server


{% for key in ('ed25519', 'rsa', 'ecdsa') if 'host_%s_key' % key in openssh_server %}
openssh-server-host-key-{{ key }}:
    file.managed:
        - name: /etc/ssh/ssh_host_{{ key }}_key
        - contents_pillar: openssh_server:host_{{ key }}_key
        - user: root
        - group: root
        - mode: 600
        - show_changes: False
        - watch_in:
            - service: openssh-server
{% endfor %}


{% set allow_from = openssh_server.get('allow_from', {}) %}
{% for family in ('ipv4', 'ipv6') %}
openssh-server-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - family: {{ family }}
        - chain: INPUT
        - dport: {{ openssh_server.port }}
        {% if family in allow_from %}
        - source: {{ allow_from[family] }}
        {% endif %}
        - jump: ACCEPT
        - proto: tcp
        - match:
            - comment
        - comment: "openssh-server: Allow incoming SSH"
{% endfor %}
