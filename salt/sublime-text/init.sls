{% set sublime = pillar.get('sublime-text', {}) %}
{% set build_def = sublime.get('build', '3114 sha256=53729a6d4fbbef56ffa25ab2eca3a351a5475ed971045551763fdde65dcdfeb2') %}
{% set build, build_hash = build_def.split() %}

sublime-text:
    file.managed:
        - name: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
        - source: https://download.sublimetext.com/sublime-text_build-{{ build }}_amd64.deb
        - source_hash: {{ build_hash }}

    pkg.installed:
        - sources:
            - sublime-text: /usr/local/src/sublime-text_build-{{ build }}_amd64.deb
