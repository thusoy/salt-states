{% set sublime = pillar.get('sublime-text', {}) %}
{% set build_def = sublime.get('build', '3143 sha256=ecd78f6fd3a61dc2d68725a368343589d8df4193434c0275cd49b2026fd0fb81') %}
{% set build, build_hash = build_def.split() %}

sublime-text:
    file.managed:
        - name: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
        - source: https://download.sublimetext.com/sublime-text_build-{{ build }}_amd64.deb
        - source_hash: {{ build_hash }}

    pkg.installed:
        - sources:
            - sublime-text: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
