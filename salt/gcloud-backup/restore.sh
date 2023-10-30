#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
    echo >&2 "usage: ./restore.sh <source>"
    echo >&2
    echo >&2 "Example: ./restore.sh gs://foobucket. Add decryption keys if necessary to your .boto config first."
    exit 1
fi

source_address=$1

# Trim trailing slash if present
gsutil -m cp -P -r "${source_address%/}"'/*' /
