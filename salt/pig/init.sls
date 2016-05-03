# Requires hadoop for non-local execution
{% from 'pig/settings.jinja' import pig with context -%}


include:
  - java


pig_home:
  file.directory:
    - name: {{ pig.home }}
    - user: root
    - group: root
    - mode: 755


pig:
  file.managed:
    - name: {{ pig.home }}/pig-{{ pig.version }}.tar.gz
    # Any solution better than curl -s http://www.apache.org/dyn/closer.cgi/pig | grep '<strong>.*</strong>' -o | head -1 | grep http://[a-z0-9\./]* -o
    # to determine this dynamically?
    - source: http://apache.lehtivihrea.org/pig/pig-{{ pig.version }}/pig-{{ pig.version }}.tar.gz
    - source_hash: https://www.apache.org/dist/pig/pig-{{ pig.version }}/pig-{{ pig.version }}.tar.gz.md5
    - require:
      - file: pig_home

  cmd.wait:
    - name: tar xf {{ pig.home }}/pig-{{ pig.version }}.tar.gz
    - cwd: {{ pig.home }}
    - watch:
      - file: pig


pig-env:
  file.managed:
    - name: /etc/profile.d/pig.sh
    - contents: 'export PATH={{ pig.home }}/pig-{{ pig.version }}/bin:$PATH'
