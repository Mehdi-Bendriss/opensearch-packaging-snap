#!/usr/bin/env bash


usage() {
cat << EOF
usage: create-certificate.sh --password password ...
To be ran / setup once per cluster.
--password        (Required)    Password for encrypting the key
--type            (Required)    Enum of either: root, admin, node, client
--name            (Optional)    Name of certificate: required for nodes and clients
--subject         (Optional)    Subject for the certificate, defaults to CN=localhost
--target-dir      (Optional)    The target directory where the certificates and related resources are creates
--help                          Shows help menu
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
target_dir="."
root_ca=""



# Args handling
function parse_args () {
    LONG_OPTS_LIST=(
        "password"
        "type"
        "name"
        "subject"
        "target-dir"
        "help"
    )
    opts=$(getopt \
      --longoptions "$(printf "%s:," "${LONG_OPTS_LIST[@]}")" \
      --name "$(basename "$0")" \
      --options "" \
      -- "$@"
    )
    eval set -- "${opts}"

    while [ $# -gt 0 ]; do
        case $1 in
            --password)
                shift
                password=$1
                ;;
            --type)
                shift
                type=$1
                ;;
            --name)
                shift
                name=$1
                ;;
            --subject)
                shift
                subject=$1
                ;;
            --target-dir)
                shift
                target_dir=$1
                ;;
            --help) usage
                exit
                ;;
        esac
        shift
    done
}

function set_defaults () {
    if [ -z "${subject}" ] && [ "${type}" != "client" ]; then
        subject="${SUBJECTS["${type}"]}"
    fi

    if [ "${type}" == "node" ] || [ "${type}" == "client" ]; then
        name="${type}.${name}"
    else
        name="${type}"
    fi

    if [ -z "${target_dir}" ]; then
        target_dir="."
    fi
}

function validate_args () {
    err_message=""
    if [ -z "${password}" ]; then
        err_message=" - '--password' is required \n"
    fi

    if ! echo "${ALLOWED_CERT_TYPES[*]}" | grep -wq "${type}"; then
        err_message="${err_message}- '--type' must be set to one of: ${ALLOWED_CERT_TYPES[*]}.\n"
    fi

    if [ -n "${name}" ] && [ "${name}" == "${type}." ]; then
        err_message="${err_message}- '--name' of the resource must be provided for nodes and clients (i.e: --name node1).\n"
    fi

    if [ -z "${subject}" ]; then
        err_message="${err_message}- '--subject' must be correctly set if specified, as it overrides the default value for local setups otherwise. \n"
    fi

    if [ -z "${target_dir}" ]; then
        err_message="${err_message}- '--target-dir' must be a correct path, or not set to point to the current directory. \n"
    fi

    if [ -n "${err_message}" ]; then
        echo -e "The following errors occurred: \n${err_message}Refer to the help menu."
        exit 1
    fi
}


# Certs creation
function create_root_certificate () {
    # generate a private key
    openssl genrsa \
        -out "${target_dir}"/root-ca-key.pem \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # generate a root certificate
    openssl req \
        -new \
        -x509 \
        -sha256 \
        -key "${target_dir}"/root-ca-key.pem \
        -out "${target_dir}"/root-ca.pem \
        -subj "${subject}" \
        -days ${LIFESPAN_DAYS}
}


function create_certificate () {
    # generate a private key certificate
    openssl genrsa \
        -out "${target_dir}"/"${name}"-key-temp.pem \
        -aes256 \
        -passout pass:"${password}" \
        ${KEY_SIZE_BITS}

    # convert created key to PKS-8 Java compatible format
    openssl pkcs8 \
        -inform PEM \
        -outform PEM \
        -in "${target_dir}"/"${name}"-key-temp.pem \
        -topk8 \
        -nocrypt \
        -v1 PBE-SHA1-3DES \
        -out "${target_dir}"/"${name}"-key.pem

    # create a CSR
    openssl req \
        -new \
        -key "${target_dir}"/"${name}"-key.pem \
        -subj "${subject}" \
        -out "${target_dir}"/"${name}".csr

    # generate the admin certificate
    openssl x509 \
        -req \
        -in "${target_dir}"/"${name}".csr \
        -CA "${target_dir}"/root-ca.pem \
        -CAkey "${target_dir}"/root-ca-key.pem \
        -CAcreateserial \
        -sha256 \
        -out "${target_dir}"/"${name}".pem \
        -days ${LIFESPAN_DAYS}
}


parse_args "$@"
set_defaults
validate_args

mkdir -p "${target_dir}"

if [[ $type == "root" ]]; then
    create_root_certificate
else
    create_certificate
fi
