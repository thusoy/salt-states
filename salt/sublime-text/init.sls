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


{% for user, values in salt['pillar.get']('sublime-text:users', {}).items() %}
{% if 'license' in values %}
sublime-text-license-{{ user }}:
    file.managed:
        - name: /home/{{ user }}/.config/sublime-text-3/Local/License.sublime_license
        - contents_pillar: sublime-text:users:{{ user }}:license
        - user: {{ user }}
        - group: {{ user }}
        - mode: 600
        - makedirs: True
{% endif %}


{% if values.get('package_control', False) %}
sublime-text-package-control:
    file.managed:
        - name: /home/tarjei/.config/sublime-text-3/Installed Packages/Package Control.sublime-package
        - source: https://packagecontrol.io/Package%20Control.sublime-package
        - source_hash: sha256=2915d1851351e5ee549c20394736b4428bc59f460fa1548d1514676163dafc88
        - require:
            - pkg: sublime-text
{% endif %}

{% endfor %}
