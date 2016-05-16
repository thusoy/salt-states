{% set pip = pillar.get('pip') %}

pip:
    pkg.purged:
        - name: python-pip

    cmd.run:
        - name: get_pip=$(tempfile) &&
            wget -qO "$get_pip" https://bootstrap.pypa.io/get-pip.py &&
            python "$get_pip" &&
            rm "$get_pip"
        - unless: pip --version
        - require:
            - pkg: pip

    pip.installed:
        {% if 'version' in pip %}
        - name: pip {{ pip.version }}
        {% else %}
        - name: pip
        - upgrade: True
        {% endif %}
        - require:
            - cmd: pip
