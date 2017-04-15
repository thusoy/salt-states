include:
    - git
    - users


{% for username, config in pillar.get('users').items() %}
{% if 'pyenv' in config.get('install', []) %}
{% set home = salt['user.info'](username)['home'] %}
pyenv-{{ username }}:
    git.latest:
        - name: https://github.com/pyenv/pyenv
        - target: {{ home }}/.pyenv

    file.managed:
        - name: {{ home }}/.bash_source/99_pyenv
        - makedirs: True
        - contents: |
            # Needs to be sourced last to ensure it stays in front of PATH
            export PYENV_ROOT=~/.pyenv
            export PATH=$PYENV_ROOT/bin:$PATH
            eval "$(pyenv init -)"
{% endif %}
{% endfor %}
