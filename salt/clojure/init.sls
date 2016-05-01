{% set version_id = '1.7.0 sha256=4de303794da1766c547f1a1baaf368abfdf49d4cd8aaa237e5b2ffbbcd03cf93' %}
{% set version, source_hash = version_id.split() %}


include:
    - java


clojure-deps:
    pkg.installed:
        - name: unzip


clojure:
    file.managed:
        - name: /usr/local/src/clojure-{{ version }}.zip
        - source: http://repo1.maven.org/maven2/org/clojure/clojure/{{ version }}/clojure-{{ version }}.zip
        - source_hash: {{ source_hash }}

    cmd.watch:
        - name: cd /usr/local/src &&
                unzip clojure-{{ version }}.zip &&
                find clojure-1.7.0 -type f -exec chmod 644 {} \; &&
                find clojure-1.7.0 -type d -exec chmod 755 {} \;
        - require:
            - pkg: clojure-deps
        - watch:
            - file: clojure
