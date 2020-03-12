#!/bin/sh

# Get the latest version of vault with a hash verified by the release key. This
# avoids having to query for the hashes for every install, ensuring that an
# attacker would have to compromise the release key to be able to modify the
# binary, not just the distribution point for the hashes and binaries.

set -eu

# Which hash from SHA256SUMS to extract
TARGET_ARCH=linux_amd64

# Create a homedir for gpg
homedir=$(mktemp -d)
trap 'rm -rf $homedir' INT TERM EXIT

main () {
    local latest_version sha256_hash
    latest_version=$(get_latest_version)
    echo "Fetching hashes for latest version ($latest_version)"
    download_checksums_and_sig "$latest_version"
    import_trusted_key
    verify_checksums
    sha256_hash=$(extract_hash)
    echo "$latest_version sha256=$sha256_hash"
}

get_latest_version () {
    # Somewhat flimsy regex, but should be obvious if it fails
    curl -s https://www.vaultproject.io/downloads/ \
        | grep -Eo '<span class="g-type-body-small">Version: <!-- -->\d+\.\d+.\d+</span>' \
        | head -1 \
        | grep -Eo '\d+\.\d+.\d+'
}

download_checksums_and_sig () {
    local version=$1
    wget -q "https://releases.hashicorp.com/vault/${version}/vault_${version}_SHA256SUMS" \
        -O "$homedir/checksums"
    wget -q "https://releases.hashicorp.com/vault/${version}/vault_${version}_SHA256SUMS.sig" \
        -O "$homedir/checksums.sig"
}

import_trusted_key () {
    gpg --homedir "$homedir" --import --quiet < "$(dirname "$0")/release-key.asc"
    # Seemed easier to hardcode the key fingerprint than try to parse the
    # output of gpg. Need to update this if the key is ever rotated.
    echo '91A6E7F85D05C65630BEF18951852D87348FFC4C:6:' \
        | gpg --homedir "$homedir" --import-ownertrust --quiet
}

verify_checksums () {
    gpg --homedir "$homedir" --verify --quiet "$homedir/checksums.sig" "$homedir/checksums"
}

extract_hash () {
    grep "$TARGET_ARCH" "$homedir/checksums" \
        | cut -d' ' -f1
}

main
