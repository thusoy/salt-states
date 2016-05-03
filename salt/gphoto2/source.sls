libgphoto2-deps:
    pkg.installed:
        - pkgs:
            - autoconf
            - autopoint
            - build-essential
            - checkinstall
            - gettext
            - libaa1-dev
            - libexif-dev
            - libgd2-xpm-dev
            - libpopt-dev
            - libtool
            - libusb-1.0-0-dev
            - libusb-dev
            - libxml2-dev
            - pkg-config


# Can't use git.latest state since it doesn't work with git 1.7 which is
# present on raspbian due to the autopoint requirement above
libgphoto2-repo:
    cmd.run:
        - name: git clone https://github.com/gphoto/libgphoto2 &&
                cd libgphoto2 &&
                git reset --hard 4f7eb8a73a387b742d636f07c8a592fa2c6916ae
        - cwd: /usr/local/src
        - unless: test -d libgphoto2 &&
                  cd libgphoto2 &&
                  test "$(git rev-parse HEAD)" = "4f7eb8a73a387b742d636f07c8a592fa2c6916ae"
        - require:
            - pkg: libgphoto2-deps

libgphoto2:
    cmd.watch:
        - name: autoreconf --install --symlink &&
                ./configure &&
                make -j{{ grains.num_cpus }} &&
                checkinstall -y --pkgname libgphoto2 make install &&
                git clean -df
        - cwd: /usr/local/src/libgphoto2
        - watch:
            - cmd: libgphoto2-repo


# Can't use git.latest state since it doesn't work with git 1.7 which is
# present on raspbian due to the autopoint requirement above
gphoto2-repo:
    cmd.run:
        - name: git clone https://github.com/gphoto/gphoto2 &&
                cd gphoto2 &&
                git reset --hard b82435b679a41193c2fbb3dbe76519c12bf89d51
        - cwd: /usr/local/src
        - unless: test -d gphoto2 &&
                  cd gphoto2 &&
                  test "$(git rev-parse HEAD)" = "b82435b679a41193c2fbb3dbe76519c12bf89d51"
        - require:
            - pkg: libgphoto2-deps

gphoto2:
    cmd.watch:
        - name: autoreconf --install --symlink &&
                ./configure &&
                make -j{{ grains.num_cpus }} &&
                checkinstall -y --pkgname gphoto2 make install &&
                git clean -df
        - cwd: /usr/local/src/gphoto2
        - watch:
            - cmd: gphoto2-repo
