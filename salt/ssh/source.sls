{% set ssh = pillar.get('ssh', {}) %}
{% set version_identifier = ssh.get('version_identifier', '7.1p1 sha256=fc0a6d2d1d063d5c66dffd952493d0cda256cad204f681de0f84ef85b2ad8428') %}
{% set version, version_hash = version_identifier.split(' ') %}
{% set install_log_file = "/usr/local/src/openssh-" + version + "-install.log" %}

openssh-deps:
    pkg.installed:
        - pkgs:
            - checkinstall
            - libpam0g-dev
            - libssl-dev
            - zlib1g-dev


# Purge openssh-client to avoid conflicts with files deployed by
# openssh-server source
openssh-client:
    pkg.removed: []


openssh-source:
    file.managed:
        - name: /usr/local/src/openssh-{{ version }}.tar.gz
        - source: http://ftp2.eu.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-{{ version }}.tar.gz
        - source_hash: {{ version_hash }}

    cmd.watch:
        - name: tar xf openssh-{{ version }}.tar.gz
        - cwd: /usr/local/src
        - watch:
            - file: openssh-source


openssh-install:
    cmd.watch:
        - name: ./configure
                    --sysconfdir=/etc/ssh
                    --prefix=/usr
                    --with-pie
                    --without-ssh1
                    --with-pam
                    --with-4in6 &&
                make -j{{ grains.num_cpus }} &&
                make install
        - cwd: /usr/local/src/openssh-{{ version }}
        - require:
            - pkg: openssh-deps
        - watch:
            - cmd: openssh-source
