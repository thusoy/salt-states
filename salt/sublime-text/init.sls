{% set sublime = pillar.get('sublime-text', {}) %}
{% set channel = sublime.get('channel', 'stable') %}

sublime-text-deps:
    pkg.installed:
        - name: apt-transport-https


sublime-text:
    pkgrepo.managed:
        - name: deb https://download.sublimetext.com/ apt/{{ channel }}/
        - key_url: salt://sublime-text/repo-key.gpg
        - require:
            - pkg: sublime-text-deps

    pkg.installed:
        - require:
            - pkgrepo: sublime-text
