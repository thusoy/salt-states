# Make sure /tmp, /var/tmp and /dev/shm are all nodev, nosuid and noexec
# Ref. NSA RHEL guide section 2.2.1.3

{% set tmp_size = salt['pillar.get']('os:tmp_size', '1073741824') %}

# TODO: This currently remounts /tmp to tmpfs, that should be configurable.
{% set tmp_line = 'tmpfs /tmp tmpfs defaults,nodev,nosuid,noexec,mode=1777,size={} 0 0'.format(tmp_size) %}
hardening-/tmp:
    file.replace:
        - name: /etc/fstab
        - pattern: ^tmpfs[ ]*/tmp .*
        - repl: {{ tmp_line }}
        - unless: grep "^{{ tmp_line }}$" /etc/fstab
        - append_if_not_found: True


{% set var_tmp_line = '/tmp /var/tmp none rw,noexec,nosuid,nodev,bind 0 0' %}
hardening-/var/tmp:
    file.replace:
        - name: /etc/fstab
        - pattern: ^/tmp
        - repl: {{ var_tmp_line }}
        - unless: grep "{{ var_tmp_line }}" /etc/fstab
        - append_if_not_found: True


{% set shm_line = 'tmpfs /dev/shm tmpfs defaults,nodev,nosuid,noexec 0 0' %}
hardening-/dev/shm:
    file.replace:
        - name: /etc/fstab
        - pattern: ^tmpfs[ ]*/dev/shm
        - repl: {{ shm_line }}
        - unless: grep "{{ shm_line }}" /etc/fstab
        - append_if_not_found: True
