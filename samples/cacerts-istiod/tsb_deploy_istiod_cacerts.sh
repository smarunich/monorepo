export FOLDER='.'
export NAME_PREFIX='internal'

function create_cert() {
  local readonly name=$1
  local readonly folder=$2
  local readonly conf=$3
  local readonly ca_cert=$4
  local readonly ca_key=$5
  local readonly ca_chain=$6

  openssl genrsa \
    -out "${FOLDER}/${name}.key" \
    4096

  # generate tsb_int_ca certs
  openssl req \
    -new \
    -config "${conf}" \
    -key "${FOLDER}/${name}.key" \
    -out "${FOLDER}/${name}.csr"

  # sign tsb_int_ca certificate with root CA
  openssl x509 \
    -req \
    -days 90 \
    -CA "${ca_cert}" \
    -CAkey "${ca_key}" \
    -CAcreateserial \
    -extensions req_ext \
    -extfile "${conf}" \
    -in "${FOLDER}/${name}.csr" \
    -out "${FOLDER}/${name}.crt"

}

cat >"${FOLDER}/istiod_intermediate_ca.cnf" <<EOF
# all the fields in this CNF are just example, Client should follow its own PKI practice to configue it properly. only key useage keycertsign is needed for istio to sign the workload certs
[ req ]
encrypt_key        = no
utf8               = yes
default_bits       = 4096
default_md         = sha256
prompt             = no
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = req_ext
[ req_distinguished_name ]
countryName         = US
stateOrProvinceName = CA
organizationName    = Example
commonName          = ISTIO Intermediate CA
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:true, pathlen:0
keyUsage             = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
subjectAltName       = @alt_names
[ alt_names ]
DNS.1 = istiod.istio-system.svc
EOF

create_cert istiod_${NAME_PREFIX}_intermediate_ca \
  "${FOLDER}" \
  "${FOLDER}/istiod_intermediate_ca.cnf" \
  "${FOLDER}/ca.crt" \
  "${FOLDER}/ca.key"

#kubectl create namespace istio-system
#kubectl create secret generic cacerts -n istio-system \
#   --from-file=ca-cert.pem="${FOLDER}/istiod_intermediate_ca.crt" \
#   --from-file=ca-key.pem="${FOLDER}/istiod_intermediate_ca.key" \
#   --from-file=root-cert.pem="${FOLDER}/ca.crt" \
#   --from-file=cert-chain.pem="${FOLDER}/istiod_intermediate_ca.crt"
