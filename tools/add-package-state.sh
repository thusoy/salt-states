#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
    echo 'usage: ./tools/add-package-state.sh <name-of-package>'
fi

package=$1

main () {
    mkdir -p "salt/$package"
    create_init
    create_readme
}

create_init () {
    cat > "salt/$package/init.sls" <<EOF
$package:
    pkg.installed
EOF
}

create_readme () {
    cat > "salt/$package/README.md" <<EOF
$package
$(echo -n "$package" | tr '[:print:]' =)

Installs $package.
EOF
}

main
