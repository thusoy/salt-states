#!/bin/sh

set -eu

if [ $# -ne 1 ]; then
    echo 'usage: get-helper-version.sh <version>'
fi

version=$1

curl -sL "https://www.dropbox.com/download?dl=packages/ubuntu/dropbox_${version}_amd64.deb" \
    | sha256sum
