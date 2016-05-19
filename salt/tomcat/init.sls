{% from "tomcat/map.jinja" import tomcat with context %}

tomcat:
  pkg.installed:
    - name: {{ tomcat.name }}

  service.running:
    - name: {{ tomcat.name }}
    - watch:
      - pkg: tomcat
      - file: tomcat

  file.append:
    - name: /etc/default/tomcat{{ tomcat.version }}
    - text:
      - JAVA_HOME={{ salt['pillar.get']('java:home', '/usr') }}
      - JAVA_OPTS="-Djava.awt.headless=true -Xmx{{ salt['pillar.get']('java:Xmx', '3G') }} -XX:MaxPermSize={{ salt['pillar.get']('java:MaxPermSize', '256m') }}"
      {% if salt['pillar.get']('java:UseConcMarkSweepGC') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:UseConcMarkSweepGC') }}"
      {% endif %}
      {% if salt['pillar.get']('java:CMSIncrementalMode') %}
      - JAVA_OPTS="$JAVA_OPTS {{ salt['pillar.get']('java:CMSIncrementalMode') }}"
      {% endif %}
      {% if salt['pillar.get']('tomcat:security') %}
      - TOMCAT{{ tomcat.version }}_SECURITY={{ salt['pillar.get']('tomcat:security', 'no') }}
      {% endif %}


tomcat-webapp-dir:
    file.directory:
        - name: /srv/tomcat-webapps


tomcat-nofile-limits:
  file.append:
    - name: /etc/security/limits.conf
    - text:
      - {{ tomcat.name }}{{ tomcat.version }} soft nofile {{ salt['pillar.get']('tomcat:soft-nofile-limit', '64000') }}
      - {{ tomcat.name }}{{ tomcat.version }} hard nofile {{ salt['pillar.get']('limit:hard-nofile-limit', '64000') }}


tomcat-server.xml:
    file.managed:
        - name: /etc/tomcat7/server.xml
        - source: salt://tomcat/server.xml
        - require:
            - file: tomcat-webapp-dir
        - watch_in:
          - service: tomcat
