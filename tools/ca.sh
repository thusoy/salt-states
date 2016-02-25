#!/bin/bash
# Management script for the vpn

set -e

PKI_DIR=/tmp

function create-directory-structure () {
    mkdir -p $PKI_DIR/ca/private
    mkdir -p $PKI_DIR/certs
}

function new-root () {
    create-directory-structure

    root_name=$1
    echo -n "Enter new root CA common name: "
    read ca_common_name
    openssl ecparam -name secp256k1 -genkey \
    | openssl pkcs8 -v2 aes-256-cbc \
              -topk8 \
              -out $PKI_DIR/ca/$root_name/private/$root_name.key
    export CA_NAME="$ca_common_name"
    export SHORT_NAME="$root_name"
    openssl req -new \
                -config $PKI_DIR/openssl.cnf \
                -out /tmp/$root_name.csr \
                -key $PKI_DIR/ca/$root_name/private/$root_name.key
    MODE=root openssl ca -selfsign \
                              -config $PKI_DIR/openssl.cnf \
                              -in /tmp/$root_name.csr \
                              -out $PKI_DIR/certs/$root_name.crt \
                              -extensions root_ca_ext \
                              -days 7000 \
                              -notext
    rm /tmp/$root_name.csr
}

function create-user-ca () {
    user_ca_name=$1
    echo -n "Enter new CA common name: "
    read ca_common_name

    export CA_NAME="$ca_common_name"
    export SHORT_NAME="$user_ca_name"

    openssl genrsa 4096 | openssl pkcs8 -v2 aes-256-cbc \
                                        -topk8 \
                                        -out $PKI_DIR/ca/$user_ca_name/private/$user_ca_name.key
    openssl req -new \
                -config $PKI_DIR/openssl.cnf \
                -out /tmp/$user_ca_name.csr \
                -key $PKI_DIR/ca/$user_ca_name/private/$user_ca_name.key
    export SHORT_NAME="vpn.thusoy.com-root" # TODO: Remove hard-coded root
    MODE=root openssl ca -config $PKI_DIR/openssl.cnf \
                         -in /tmp/$user_ca_name.csr \
                         -out $PKI_DIR/ca/$user_ca_name.crt \
                         -extensions signing_ca_ext \
                         -days 3650 \
                         -notext
   rm /tmp/$user_ca_name.csr
}

function create-server-cert () {
    server_fqdn=$1

    export SHORT_NAME="$server_fqdn"
    export CA_NAME="$server_fqdn"

    openssl req -new \
                -config $PKI_DIR/tls-server-openssl.cnf \
                -out /tmp/$server_fqdn.csr \
                -keyout $PKI_DIR/certs/$server_fqdn.key
    export SHORT_NAME="vpn.thusoy.com-root" # TODO: Remove hard-coded root
    MODE=root openssl ca -config $PKI_DIR/openssl.cnf \
               -in /tmp/$server_fqdn.csr \
               -out $PKI_DIR/certs/$server_fqdn.crt \
               -extensions server_ext \
               -notext
    rm /tmp/$server_fqdn.csr
}

function create-new-user () {
    create-new-user-request $1
    sign-user-request $1
}

function create-new-user-request () {
    username=$1
    export COMMON_NAME="$username"

    # Create encrypted private key:
    #openssl genrsa 4096 | openssl pkcs8 -v2 aes-256-cbc \
    #                                    -topk8 \
    #                                    -out /tmp/$username.key
    # Create plaintext private key:
    openssl genrsa -out /tmp/$username.key 4096
    openssl req -new \
                -key /tmp/$username.key \
                -sha256 \
                -out /tmp/$username.csr \
                -nodes \
                -config $PKI_DIR/client-openssl.conf
}

function sign-user-request () {
    export SHORT_NAME="vpn.thusoy.com-user-ca" # TODO: Remove hard-coded CA
    openssl ca -config $PKI_DIR/openssl.cnf \
               -in /tmp/$username.csr \
               -out $PKI_DIR/certs/$username.crt
    rm /tmp/$username.csr
    generate-client-conf $1
}

function generate-client-conf () {
    TEMPLATE="/etc/openvpn/client-config-template.ovpn"
    FILEEXT=".ovpn"
    CRT=".crt"
    KEY=".key"
    ROOT_CA="$PKI_DIR/certs/vpn.thusoy.com-root.crt"
    USER_CA="$PKI_DIR/ca/vpn.thusoy.com-user-ca.crt"
    TA="ta.key"
    NAME=$1
    USER_PRIVATE_KEY=/tmp/$NAME$KEY
    NEW_CONFIG_FILE=/tmp/$NAME$FILEEXT
    CLIENT_CERT=$PKI_DIR/certs/$NAME$CRT

    # 1st verify that client's certificate exists
    if [ ! -f $CLIENT_CERT ]; then
        echo "[ERROR]: Client certificate not found: $CLIENT_CERT"
        exit
    fi
    echo "Client's cert found: $CLIENT_CERT"


    # Then, verify that there is a private key for that client
    if [ ! -f $USER_PRIVATE_KEY ]; then
        echo "[ERROR]: Client Private Key not found: $USER_PRIVATE_KEY"
        exit
    fi
    echo "Client's Private Key found: $USER_PRIVATE_KEY"

    # Confirm the CA public key exists
    if [ ! -f $ROOT_CA ]; then
     echo "[ERROR]: CA cert not found: $ROOT_CA"
     exit
    fi
    echo "CA cert found: $ROOT_CA"

    # Confirm the tls-auth ta key file exists
    #if [ ! -f $TA ]; then
    # echo "[ERROR]: tls-auth Key not found: $TA"
    # exit
    #fi
    #echo "tls-auth Private Key found: $TA"

    # Ready to make a new .ovpn file - Start by populating with the default file
    cat $TEMPLATE > $NEW_CONFIG_FILE

    # Now, append the CA Public Cert
    echo "<ca>" >> $NEW_CONFIG_FILE
    cat $ROOT_CA >> $NEW_CONFIG_FILE
    echo "</ca>" >> $NEW_CONFIG_FILE

    # Next append the client Public Cert
    echo "<cert>" >> $NEW_CONFIG_FILE
    cat $CLIENT_CERT | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >> $NEW_CONFIG_FILE
    cat $USER_CA >> $NEW_CONFIG_FILE
    echo "</cert>" >> $NEW_CONFIG_FILE

    # Then, append the client Private Key
    echo "<key>" >> $NEW_CONFIG_FILE
    cat $USER_PRIVATE_KEY >> $NEW_CONFIG_FILE
    echo "</key>" >> $NEW_CONFIG_FILE

    # Finally, append the TA Private Key
    #echo "<tls-auth>" >> $NEW_CONFIG_FILE
    #cat $TA >> $NEW_CONFIG_FILE
    #echo "</tls-auth>" >> $NEW_CONFIG_FILE

    echo "Done! $NEW_CONFIG_FILE Successfully Created."
}

function revoke-user () {
    username=$1
    user_cert="$PKI_DIR/certs/$username.crt"

    if [ ! -f "$user_cert" ]; then
        echo "ERROR: Could not find certificate for $username, tried $user_cert"
        exit 1
    fi

    export SHORT_NAME="vpn.thusoy.com-user-ca"
    openssl ca -config $PKI_DIR/openssl.cnf \
               -revoke $user_cert
    update-user-crl
}

function update-user-crl () {
    export SHORT_NAME="vpn.thusoy.com-user-ca"
    openssl ca -config $PKI_DIR/openssl.cnf -gencrl -out $PKI_DIR/../user-crl.pem
}

function show-help () {
    echo "Usage: manage <func> [<args>]"
    echo
    echo "Functions:"
    echo "   new-root <name-of-root-ca>"
    echo "   create-user-ca <name-of-user-ca>"
    echo "   create-server-cert <FQDN of server>"
    echo "   create-new-user-request <username>"
    echo "   sign-user-request <csr>"
    echo "   create-new-user <username>"
    echo "   revoke-user <username>"
}

case $1 in
    new-root)
        new-root $2
    ;;
    create-user-ca)
        create-user-ca $2
    ;;
    create-server-cert)
        create-server-cert $2
    ;;
    create-new-user)
        create-new-user $2
    ;;
    revoke-user)
        revoke-user $2
    ;;
    update-user-crl)
        update-user-crl
    ;;
    *)
        show-help
    ;;
esac

