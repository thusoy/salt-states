{% set sublime = pillar.get('sublime-text', {}) %}
{% set build_def = sublime.get('build', '3126 sha256=f3f31634c05243e33a82a96e82c3cd691958057489e47eebe8ac3b0c0e6dd3b4') %}
{% set build, build_hash = build_def.split() %}

sublime-text:
    file.managed:
        - name: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
        - source: https://download.sublimetext.com/sublime-text_build-{{ build }}_amd64.deb
        - source_hash: {{ build_hash }}

    pkg.installed:
        - sources:
            - sublime-text: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
