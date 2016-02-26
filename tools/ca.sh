#!/bin/bash
# Management script for the vpn

set -e

PKI_DIR=/tmp/ca

function create-directory-structure () {
    mkdir -p $PKI_DIR/ca/private
    mkdir -p $PKI_DIR/certs
}


function new-root () {
    create-directory-structure
    dump-openssl.cnf

    local root_name="$1"
    mkdir -p "$PKI_DIR/ca/$root_name/"{private,db}
    touch "$PKI_DIR/ca/$root_name/db/db"
    echo 01 > "$PKI_DIR/ca/$root_name/db/serial"
    echo 01 > "$PKI_DIR/ca/$root_name/db/crl.srl"
    echo -n "Enter new root CA common name: "
    read ca_common_name
    local private_key="$PKI_DIR/ca/$root_name/private/$root_name.key"
    openssl ecparam -name secp256k1 -genkey -out "$private_key"
    export CA_NAME="$ca_common_name"
    export SHORT_NAME="$root_name"
    cat <<EOF
[INFO] Now we'll create the CSR, enter the key you just created.
EOF
    local old_dir=$(pwd)
    cd "$PKI_DIR"
    local csr=$(openssl req -new \
                -config "$PKI_DIR/openssl.cnf" \
                -key "$private_key" \
                -nodes)
    cat <<EOF
[INFO] We'll now self-sign our root certificate, enter the key you just created again.
EOF
    MODE=root openssl ca -selfsign \
                         -config "$PKI_DIR/openssl.cnf" \
                         -in <(echo "$csr") \
                         -out "$PKI_DIR/certs/$root_name.crt" \
                         -extensions root_ca_ext \
                         -days 7300 \
                         -notext

    # store the private to disk encrypted
    cat <<EOF
[INFO] You'll now be asked for the passphrase under which you want to encrypt your new
       root CA. Generate a strong one and store it securely.

       Hint: You can create strong keys by using "openssl rand -base64 30"
EOF
    cat "$private_key" | openssl pkcs8 -v2 aes-256-cbc \
                  -topk8 \
                  -out "$PKI_DIR/ca/$root_name/private/$root_name.key"
    cd "$old_dir"
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

function dump-openssl.cnf () {
    cat <<"EOF" > $PKI_DIR/openssl.cnf
# Simple Root CA

# The [default] section contains global constants that can be referred to from
# the entire configuration file. It may also hold settings pertaining to more
# than one openssl command.

MODE                    = root # Set root to act as root CA
mode                    = ${ENV::MODE}
CA_NAME                 = default-ca-name
ca_name                 = ${ENV::CA_NAME}
ca                      = ${ENV::SHORT_NAME}              # CA name
dir                     = .                   # Top dir

# The next part of the configuration file is used by the openssl req command.
# It defines the CA's key pair, its DN, and the desired extensions for the CA
# certificate.

[ req ]
encrypt_key             = yes                   # Protect private key
default_md              = sha256                # MD to use
utf8                    = yes                   # Input is UTF-8
string_mask             = utf8only              # Emit UTF-8 strings
prompt                  = no                    # Don't prompt for DN
distinguished_name      = ca_dn                 # DN section
req_extensions          = ca_reqext             # Desired extensions

[ ca_dn ]
organizationName        = "Megacool"
organizationalUnitName  = "Megacool Internal Infrastructure"
commonName              = $ca_name

[ ca_reqext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash

# The remainder of the configuration file is used by the openssl ca command.
# The CA section defines the locations of CA assets, as well as the policies
# applying to the CA.

[ ca ]
default_ca              = ${mode}_ca               # The default CA section

[ root_ca ]
certificate             = $dir/certs/$ca.crt       # The CA cert
private_key             = $dir/ca/$ca/private/$ca.key # CA private key
new_certs_dir           = $dir/ca/$ca           # Certificate archive
serial                  = $dir/ca/$ca/db/serial # Serial number file
crlnumber               = $dir/ca/$ca/db/crl.srl # CRL number file
database                = $dir/ca/$ca/db/db     # Index file
unique_subject          = no                    # Require unique subject
default_days            = 365                   # How long to certify for
default_md              = sha512                # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = ca_default            # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = none                  # Copy extensions from CSR
x509_extensions         = signing_ca_ext        # Default cert extensions
default_crl_days        = 365                   # How long before next CRL
crl_extensions          = crl_ext               # CRL extensions

# Naming policies control which parts of a DN end up in the certificate and
# under what circumstances certification should be denied.

[ match_pol ]
organizationName        = match                 # Must match 'Simple Inc'
organizationalUnitName  = optional              # Included if present
commonName              = supplied              # Must be present

[ any_pol ]
domainComponent         = optional
countryName             = optional
stateOrProvinceName     = optional
localityName            = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = optional
emailAddress            = optional

# Certificate extensions define what types of certificates the CA is able to
# create.

[ root_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
crlDistributionPoints   = user_crl, root_crl

[ signing_ca_ext ]
keyUsage                = critical,keyCertSign,cRLSign
basicConstraints        = critical,CA:true,pathlen:0
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
crlDistributionPoints   = user_crl, root_crl

[ server_ext ]
keyUsage                = critical,digitalSignature,keyEncipherment
basicConstraints        = CA:false
extendedKeyUsage        = serverAuth
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always
crlDistributionPoints   = user_crl, root_crl

[ user_crl ]
fullname = URI:https://vpn.thusoy.com/user-crl.pem
reasons  = privilegeWithdrawn, keyCompromise

[ root_crl ]
fullname  = URI:https://vpn.thusoy.com/root-crl.pem
reasons   = CACompromise, superseded, cessationOfOperation
CRLIssuer = dirName:root_crl_issuer

[ root_crl_issuer ]
O = thusoy.com
OU = thusoy.com VPN
CN = vpn.thusoy.com

[ signing_ca ]
certificate             = $dir/ca/$ca.crt       # The CA cert
private_key             = $dir/ca/$ca/private/$ca.key # CA private key
new_certs_dir           = $dir/certs            # Certificate archive
serial                  = $dir/ca/$ca/db/serial # Serial number file
crlnumber               = $dir/ca/$ca/db/crl.srl # CRL number file
database                = $dir/ca/$ca/db/db     # Index file
unique_subject          = no                    # Require unique subject
default_days            = 365                   # How long to certify for
default_md              = sha256                # MD to use
policy                  = match_pol             # Default naming policy
email_in_dn             = no                    # Add email to cert DN
preserve                = no                    # Keep passed DN ordering
name_opt                = ca_default            # Subject DN display options
cert_opt                = ca_default            # Certificate display options
copy_extensions         = copy                  # Copy extensions from CSR
default_crl_days        = 365                   # How long before next CRL
crl_extensions          = crl_ext               # CRL extensions

# CRL extensions exist solely to point to the CA certificate that has issued
# the CRL.

[ crl_ext ]
authorityKeyIdentifier  = keyid:always,issuer:always
EOF
}


case $1 in
    new-root)
        new-root "$2"
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

