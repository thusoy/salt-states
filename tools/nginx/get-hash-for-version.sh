#!/bin/bash

set -eu

if [ $# -eq 1 ]; then
    version="$1"
else
    echo "Usage: $(basename $0) <version>"
    exit 1
fi

source_uri="https://nginx.org/download/nginx-$version.tar.gz"
source_file=$(basename "$source_uri")
signature_uri="$source_uri.asc"
state_dir=$(dirname "$0")

temp_dir=$(mktemp -d)

cleanup () {
    rm -rf "$temp_dir"
}

trap cleanup INT TERM EXIT

find "$state_dir/keys/" -type f -name "*.asc" -print0 | while read -d $'\0' key; do
    key_name=$(basename "$key")
    gpg_key="${key_name%.asc}.gpg"
    gpg \
        --yes \
        -o "$temp_dir/$gpg_key" \
        --dearmor "$key"
done

cd "$temp_dir"
cat *.gpg >> "$temp_dir/keyring.gpg"
wget -q "$source_uri"
wget -q "$signature_uri"

gpg \
    --status-fd 1 \
    --no-default-keyring \
    --keyring ./keyring.gpg \
    --trust-model always \
    --verify *.asc \
    2>/dev/null

get_sha256 () {
    local digest
    digest=$(which sha256sum >/dev/null && sha256sum "$1" || shasum -a 256 "$1")
    echo "sha256=$digest"
}

if [ $? -eq 0 ]; then
    echo
    digest=$(get_sha256 "$source_file" | cut -d' ' -f1)
    echo "$version $digest"
fi
