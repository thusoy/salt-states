#!/bin/sh

set -e

if [ $# -eq 1 ]; then
    version="$1"
else
    echo "Usage: $(basename $0) <version>"
fi

sha256_digest () {
    # Use sha256sum on linux, shasum -a 256 on OSX
    which sha256sum && sha256sum $@ || shasum -a 256 $@
}

source_uri="http://ftp2.eu.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-$version.tar.gz"
source_file=$(basename "$source_uri")
signature_uri="$source_uri.asc"
state_dir=$(dirname $0)
key="$state_dir/RELEASE_KEY.asc"

temp_dir=$(mktemp -d)

function cleanup {
    rm -rf "$temp_dir"
}
trap cleanup EXIT

gpg \
    --yes \
    -o "$temp_dir/RELEASE_KEY.gpg" \
    --dearmor "$key"

cd "$temp_dir"
wget "$source_uri"
wget "$signature_uri"

gpg \
    --status-fd 1 \
    --no-default-keyring \
    --keyring "./RELEASE_KEY.gpg" \
    --trust-model always \
    --verify *.asc \
    2>/dev/null

echo
echo "sha256sum:"
sha256_digest "$source_file"
