{% set version_spec = '1.8.1 sha256=ed0e1ae0f35aecd47e0b3dfb486a230984a08ceda3b371486add4d42714a693d' %}
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
