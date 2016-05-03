{% set darktable = pillar.get('darktable', {}) %}
{% set version_spec = darktable.get('version_spec', '2.0.0 sha256=d4f2f525bbbb1355bc3470e74cc158d79d7e236f3925928f67a88461f1df7cb1') %}
{% set version, version_hash = version_spec.split() %}


darktable-deps:
    pkg.installed:
        - pkgs:
            - cmake
            - fop
            - intltool
            - libgraphicsmagick1-dev
            - libatk1.0-dev
            - libcairo2-dev
            - libcolord-dev
            - libcurl4-gnutls-dev
            - libdbus-glib-1-dev
            - libexiv2-dev
            - libgnome-keyring-dev
            - libwebp-dev
            - libflickcurl-dev
            - libfontconfig1-dev
            - libfreetype6-dev
            - libsecret-1-dev
            - libopenjpeg-dev
            - libgomp1
            - libgphoto2-2-dev
            - libgtk2.0-dev
            - libjpeg-dev
            - liblcms2-dev
            - liblensfun-dev
            - liblua5.2-dev
            - libopenexr-dev
            - libpng12-dev
            - librsvg2-dev
            - libsoup2.4-dev
            - libsqlite3-dev
            - libstdc++-4.9-dev
            - libtiff5-dev
            - libxml2-dev
            - libgtk-3-dev
            - libjson-glib-dev
            - libpugixml-dev


darktable:
    file.managed:
        - name: /usr/local/src/darktable-{{ version }}.tar.xz
        - source: https://github.com/darktable-org/darktable/releases/download/release-{{ version }}/darktable-{{ version }}.tar.xz
        - source_hash: {{ version_hash }}

    cmd.wait:
        - name: tar xf darktable-{{ version }}.tar.xz &&
                cd darktable-{{ version }} &&
                mkdir build &&
                cd build &&
                cmake -DCMAKE_BUILD_TYPE=Release .. &&
                make -j{{ grains.num_cpus }} &&
                make install
        - cwd: /usr/local/src
        - require:
            - pkg: darktable-deps
        - watch:
            - file: darktable
