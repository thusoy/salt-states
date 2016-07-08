{% set git = pillar.get('git', {}) %}
{% set version_identifier = git.get('version', '2.9.0 sha256=f41fa97949948fbf49af94a43d779e072a5452c6b5039d86ffa41ebab747b409') %}
{% set version, source_hash = version_identifier.split() %}
{% set source = git.get('source_root', '/usr/local/src') %}
{% set prefix = git.get('prefix', '/') %}
{% set package_format = '.tar.xz' %}
{% set git_package = source + '/git-' + version + package_format %}

git-deps:
    pkg.installed:
        - names:
            - build-essential
            - gettext
            - libcurl4-gnutls-dev
            - libexpat1-dev
            - libssl-dev
            # Specify the virtual for libz-dev manually, as salt will report failure otherwise:
            - zlib1g-dev

git:
    file.managed:
        - name: {{ git_package }}
        - source: https://www.kernel.org/pub/software/scm/git/git-{{ version }}{{ package_format}}
        - source_hash: {{ source_hash }}

    cmd.wait:
        - name: tar -xf {{ git_package }} &&
                cd git-{{ version }} &&
                make -j{{ grains.num_cpus }} prefix={{ prefix }} all &&
                make prefix={{ prefix }} install
        - cwd: {{ source }}
        - require:
            - pkg: git-deps
        - watch:
            - file: git

    pkg.removed: []
