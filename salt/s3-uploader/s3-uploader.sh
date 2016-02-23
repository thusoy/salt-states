#!/bin/bash

if [ $# -ne 2 ]; then
    echo >&2 "usage: $(basename "$0") <src> <dest>"
    exit 1
fi

src="$1"
dest="$2"

get_bucket_from_destination () {
    echo "$dest" | cut -d/ -f1
}

get_object_key_from_destination () {
    echo "$dest" | cut -d/ -f2-
}

bucket="$(get_bucket_from_destination)"
object_key="$(get_object_key_from_destination)"
access_key_id={{ key }}
access_secret_key={{ secret }}
content_type="$(file --mime-type --brief "$src")"
date_value=$(date -R)
string_to_sign="PUT\n\n${content_type}\n${date_value}\n/${dest}"
signature=$(echo -en ${string_to_sign} | openssl sha1 -hmac ${access_secret_key} -binary | base64)
curl -L -X PUT -T "${src}" \
    -H "Date: ${date_value}" \
    -H "Content-Type: ${content_type}" \
    -H "Authorization: AWS ${access_key_id}:${signature}" \
    https://${bucket}.s3.amazonaws.com/${object_key}
