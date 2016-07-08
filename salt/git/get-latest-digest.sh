#!/bin/sh

set -e

release_key_path=$(dirname "$0")/RELEASE_KEY.asc
release_key=$(cat "$release_key_path")

tempdir=$(mktemp -d)

cleanup () {
    rm -rf "$tempdir"
}

trap cleanup INT TERM EXIT

cd $tempdir

wget https://www.kernel.org/pub/software/scm/git/sha256sums.asc --quiet

echo "$release_key" | gpg --homedir . --import --quiet
gpg --homedir . --verify sha256sums.asc 2> /dev/null

# We only get here if the verify succeeded

latest_version=$(grep -E "git-[2-9]\..*\.tar\.xz" sha256sums.asc | tail -1)
echo "sha256=$latest_version"
