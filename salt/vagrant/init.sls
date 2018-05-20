{% set version_spec = '2.1.1 sha256=cee18b6f3b1209ea5878c22cfd84a9f0004f20ef146cb7a18aada19162928a0f' %}
{% set version, version_hash = version_spec.split() %}


vagrant:
    file.managed:
        - name: /usr/local/src/vagrant-{{ version }}.deb
        - source: https://releases.hashicorp.com/vagrant/{{ version }}/vagrant_{{ version }}_x86_64.deb
        - source_hash: {{ version_hash }}

    cmd.wait:
        - name: dpkg -i /usr/local/src/vagrant-{{ version }}.deb
        - watch:
            - file: vagrant
