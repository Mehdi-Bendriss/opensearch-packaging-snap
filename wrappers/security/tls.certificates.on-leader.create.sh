#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap ... -p password
To be ran / setup once per cluster.
-p    | --password        (Required)    Password for encrypting the node / client key
-r    | --root_subject    (Optional)    Subject for the root certificate
-a    | --admin_subject   (Optional)    Subject for the admin certificate
-h    | --help                          Shows help menu
EOF
}


password=""
root_subject="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=localhost" # CN=root.dns.a-record
admin_subject="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=A"


function parse_and_validate_args () {

    function parse () {
        while [ "$1" != "" ]; do
            case $1 in
                -p | --password)
                    shift
                    password=$1
                    ;;

                -r | --root_subject)
                    shift
                    root_subject=$1
                    ;;

                -a | --admin_subject)
                    shift
                    admin_subject=$1
                    ;;

                -h | --help) usage
                    exit
                    ;;

                * ) usage
                    exit 1
            esac
            shift
        done
    }

    function validate () {
        err_message=""
        if [ -z "${password}" ]; then
            err_message="Password is required"
        fi

        if [ -z "${root_subject}" ]; then
            err_message="${err_message}\nThe root subject must be correctly set if specified, as it overrides the default value for local setups."
        fi

        if [ -z "${admin_subject}" ]; then
            err_message="${err_message}\nThe admin subject must be correctly set if specified, as it overrides the default value for local setups."
        fi

        if [ -n "${err_message}" ]; then
            echo -e "${err_message}"
            exit 1
        fi
    }

    parse "$@"
    validate
}



function run () {
    # --- Root CA
    # generate a private key
    openssl genrsa \
        -out root-ca-key.pem \
        -aes256 \
        -passout pass:"${password}" \
        2048


    # generate a root certificate
    openssl req \
        -new \
        -x509 \
        -sha256 \
        -key root-ca-key.pem \
        -out root-ca.pem \
        -subj "${root_subject}" \
        -days 730


    # --- Admin certificate
    # generate an admin certificate
    openssl genrsa \
        -out admin-key-temp.pem \
        2048

    # generate a PKS-8 Java compatible key
    openssl pkcs8 \
        -inform PEM \
        -outform PEM \
        -in admin-key-temp.pem \
        -topk8 \
        -nocrypt \
        -v1 PBE-SHA1-3DES \
        -out admin-key.pem

    # create a CSR
    openssl req \
        -new \
        -key admin-key.pem \
        -subj "${admin_subject}" \
        -out admin.csr

    # generate the admin certificate
    openssl x509 \
        -req \
        -in admin.csr \
        -CA root-ca.pem \
        -CAkey root-ca-key.pem \
        -CAcreateserial \
        -sha256 \
        -out admin.pem \
        -days 730
}


parse_and_validate_args "$@"
run
