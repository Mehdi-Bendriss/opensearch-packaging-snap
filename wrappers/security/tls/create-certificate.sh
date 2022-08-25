#!/usr/bin/env bash


usage() {
cat << EOF
usage: snap ... -p password
To be ran / setup once per cluster.
-p    | --password        (Required)    Password for encrypting the key
-t    | --type            (Required)    Enum of either: root, admin, node, client
-n    | --name            (Optional)    Name of certificate: required for nodes and clients
-s    | --subject         (Optional)    Subject for the certificate, defaults to CN=localhost
-r    | --root-ca         (Optional)    Must be set for creating nodes / client certificates
-h    | --help                          Shows help menu
EOF
}


# Defaults
ALLOWED_CERT_TYPES=("root" "admin" "node" "client") # "node" refers to the transport layer, whereas "client" refers to the "Rest" layer
KEY_SIZE_BITS=2048
LIFESPAN_DAYS=730
declare -A SUBJECTS=( ["root"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=localhost"  # CN=root.dns.a-record
                      ["admin"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=A"
                      ["node"]="/C=DE/ST=Berlin/L=Berlin/O=Canonical/OU=DataPlatform/CN=localhost")  # CN=node1.dns.a-record


# Args
password=""
type=""
name=""
subject=""
root_ca=""



# Args handling
function parse_args () {
    while [ "$1" != "" ]; do
        case $1 in
            -p | --password)
                shift
                password=$1
                ;;

            -t | --type)
                shift
                type=$1
                ;;

            -n | --name)
                shift
                name=$1
                ;;

            -s | --subject)
                shift
                subject=$1
                ;;

            -r | --root-ca)
                shift
                root_ca=$1
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

function set_defaults () {
    if [ -z "${subject}" ] && [ "${type}" != "client" ]; then
        subject="${SUBJECTS[${type}]}"
    fi

    if [ "${type}" == "node" ] || [ "${type}" == "client" ]; then
        name="${type}.${name}"
    else
        name="${type}"
    fi
}

function validate_args () {
    err_message=""
    if [ -z "${password}" ]; then
        err_message="\t- Password is required \n"
    fi

    if ! echo "${ALLOWED_CERT_TYPES[*]}" | grep -wq "${type}"; then
        err_message="\t- The cert type must be set to one of: ${ALLOWED_CERT_TYPES[*]}"
    fi

    if [ -n "${name}" ] && [ "${name}" == "${type}." ]; then
        err_message="\t- The name of the resource must be provided for nodes and clients (i.e: --name node1)."
    fi

    if [ -z "${subject}" ]; then
        err_message="${err_message}\t- The subject must be correctly set if specified, as it overrides the default value for local setups otherwise. \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}"
        exit 1
    fi
}


# Certs creation
function create_root_certificate () {
    # generate a private key
    openssl genrsa \
        -out root-ca-key.pem \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # generate a root certificate
    openssl req \
        -new \
        -x509 \
        -sha256 \
        -key root-ca-key.pem \
        -out root-ca.pem \
        -subj "${subject}" \
        -days ${LIFESPAN_DAYS}
}


function create_certificate () {
    # generate a private key certificate
    openssl genrsa \
        -out "${name}"-key-temp.pem \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # convert created key to PKS-8 Java compatible format
    openssl pkcs8 \
        -inform PEM \
        -outform PEM \
        -in "${name}"-key-temp.pem \
        -topk8 \
        -nocrypt \
        -v1 PBE-SHA1-3DES \
        -out "${name}"-key.pem

    # create a CSR
    openssl req \
        -new \
        -key "${name}"-key.pem \
        -subj "${subject}" \
        -out "${name}".csr

    # generate the admin certificate
    openssl x509 \
        -req \
        -in "${name}".csr \
        -CA root-ca.pem \
        -CAkey root-ca-key.pem \
        -CAcreateserial \
        -sha256 \
        -out "${name}".pem \
        -days ${LIFESPAN_DAYS}
}



parse_args "$@"
set_defaults
validate_args

if [[ $type == "root" ]]; then
    create_root_certificate
else
    create_certificate
fi
