# Based on https://github.com/saltstack-formulas/sun-java-formula
{% from 'java/settings.sls' import java with context -%}

include:
    - curl

{{ java.prefix }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755


unpack-jdk-tarball:
  cmd.run:
    - name: curl {{ java.dl_opts }} '{{ java.source_url }}' | tar xz --no-same-owner
    - cwd: {{ java.prefix }}
    - unless: test -d {{ java.java_real_home }}
    - require:
      - file: {{ java.prefix }}
      - pkg: curl

  alternatives.install:
    - name: java-home-link
    - link: {{ java.java_home }}
    - path: {{ java.java_real_home }}
    - priority: 30


jdk-config:
  file.managed:
    - name: /etc/profile.d/java.sh
    - source: salt://java/java.sh
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      java_home: {{ java.java_home }}
