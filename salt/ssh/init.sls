{% set ssh = pillar.get('ssh', {}) %}
{% set minumum_modulus_size = ssh.get('minumum_modulus_size', 2000) %}
{% set install_from_source = ssh.get('install_from_source', True) %}
{% set two_factor_auth = ssh.get('two_factor_auth', True) %}
{% set key_types = ssh.get('key_types', ('ed25519', 'rsa')) %}


{% if install_from_source or two_factor_auth %}
include:
    {% if install_from_source %}
    - .source
    {% endif %}
    {% if two_factor_auth %}
    - .two_factor_auth
    {% endif %}
{% endif %}


ssh:
  user.present:
    - name: sshd
    - system: True
    - createhome: False
    - home: /var/run/sshd
    - shell: /usr/sbin/nologin

  {% if not install_from_source %}
  pkg.installed:
    - name: openssh-server
  {% endif %}

  service.running:
    - enable: True
    - watch:
       - file: ssh

  init_script.managed:
    - systemd: salt://ssh/ssh-systemd
    - sysvinit: salt://ssh/ssh-sysvinit
    - upstart: salt://ssh/ssh-upstart
    - template: jinja
    - context:
        install_from_source: {{ install_from_source }}

  file.managed:
    - name: /etc/ssh/sshd_config
    - source: salt://ssh/sshd_config
    - template: jinja
    - require:
      {% if install_from_source %}
      - cmd: openssh-install
      {% else %}
      - pkg: ssh
      {% endif %}


# Delete ssh moduli weaker than 2048 bits
ssh-moduli:
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
            - service: ssh

{% for key_type in key_types %}
{% if ('host_%s_key' % key_type) in ssh %}
ssh-host-key-{{ key_type }}:
    file.managed:
        - name: /etc/ssh/ssh_host_{{ key_type }}_key
        - contents_pillar: ssh:host_{{ key_type }}_key
        - user: root
        - group: root
        - mode: 600
        - show_diff: False
        - watch_in:
            - service: ssh
{% endif %}
{% endfor %}


ssh-remove-unused-host-keys:
    cmd.run:
        - name: find /etc/ssh -type f -name "ssh_host_*_key*" {% for key_type in key_types %} ! -name "ssh_host_{{ key_type }}_key*" {% endfor %} -delete -print
        - onlyif: find /etc/ssh -type f -name "ssh_host_*_key*" {% for key_type in key_types %} ! -name "ssh_host_{{ key_type }}_key*" {% endfor %} | grep .


# Make sure an ed25519 keys exist, even if not managed through pillar
ssh-host-key-ed25519-exists:
    cmd.run:
        - name: ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -P ''
        - unless: test -f /etc/ssh/ssh_host_ed25519_key
        - watch_in:
            - service: ssh


{% for family in ('ipv4', 'ipv6') %}
ssh-firewall-{{ family }}:
    firewall.append:
        - table: filter
        - family: {{ family }}
        - chain: INPUT
        - dport: {{ ssh.get('port', 22) }}
        - jump: ACCEPT
        - proto: tcp
        - match: comment
        - comment: "ssh: Allow incoming SSH"


ssh-firewall-outgoing-{{ family }}:
    firewall.append:
        - family: {{ family }}
        - chain: OUTPUT
        - table: filter
        - proto: tcp
        - sport: {{ ssh.get('port', 22) }}
        - match:
            - comment
            - owner
            - state
        - comment: "ssh: Allow replies to SSH connections"
        - uid-owner: root
        - connstate: ESTABLISHED
        - jump: ACCEPT
{% endfor %}
