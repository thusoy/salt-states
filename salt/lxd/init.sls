{% set version_spec = '0.27 sha256=30464e8af7bf01f8d220a0eae64f61ca7bf849d58b9c6fb547400943ee228aea' %}
{% set version, source_hash = version_spec.split() %}

lxd:
    file.managed:
        - name: /usr/local/src/lxd-{{ version }}.tar.gz
        - source: https://linuxcontainers.org/downloads/lxd/lxd-{{ version }}.tar.gz
        - source_hash: {{ source_hash }}

    cmd.wait:
        - name: tar xf lxd-{{ version }}.tar.gz &&
                cd lxd-{{ version }}
        - cwd: /usr/local/src
        - watch:
            - file: lxd
