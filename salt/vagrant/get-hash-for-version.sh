#!/bin/sh

set -e


if [ $# -eq 1 ]; then
    version="$1"
else
    echo "Usage: $(basename $0) <version>"
fi


temp_dir=$(mktemp -d)
local_hashes="$temp_dir/hashes.txt"
state_dir=$(dirname $0)
key="$state_dir/release-key.asc"


function cleanup {
    rm -rf "$temp_dir"
}
trap cleanup EXIT


get_hashes_with_sig () {
    local hash_url="https://releases.hashicorp.com/vagrant/$version/vagrant_${version}_SHA256SUMS"
    local sig_url="${hash_url}.sig"
    wget -qO "$local_hashes" "$hash_url"
    wget -qO "$local_hashes.sig" "$sig_url"
}

verify_hashes () {
    # Remove ASCII armoring of key to use it as a keyring directly
    local gpg_key="$temp_dir/RELEASE_KEY.gpg"
    gpg \
        --yes \
        -o "$gpg_key" \
        --dearmor "$key"

    # Do the verification
    set +e
    local gpg_output
    gpg_output=$(gpg \
        --status-fd 1 \
        --no-default-keyring \
        --keyring "$gpg_key" \
        --trust-model always \
        --verify "$local_hashes.sig" \
        2>/dev/null)
    gpg_status=$?
    set -e
    if [ $gpg_status -ne 0 ]; then
        echo "Failed to verify hashes, could be corrupt download, MitM, or something else."
        printf "GPG said the following:\n$gpg_output\n"
        exit $gpg_status
    fi
}

print_hash () {
    local sha256hash=$(grep x86_64.deb "$local_hashes" \
    | cut -d " " -f1)
    echo "sha256=$sha256hash"
}

get_hashes_with_sig
verify_hashes
print_hash
