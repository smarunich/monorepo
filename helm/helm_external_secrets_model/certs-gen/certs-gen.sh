export FOLDER="."
export TSB_FQDN="ea2p3demo.cx.tetrate.info"

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
    -days 365 \
    -CA "${ca_cert}" \
    -CAkey "${ca_key}" \
    -CAcreateserial \
    -extensions req_ext \
    -extfile "${conf}" \
    -in "${FOLDER}/${name}.csr" \
    -out "${FOLDER}/${name}.crt"

}

cat >"${FOLDER}/ca.cnf" <<EOF
# all the fields in this CNF are just example, Client should follow its own PKI practice to configue it properly
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
commonName          = SelfSignedRootCA
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:true
keyUsage             = critical, digitalSignature, nonRepudiation, keyEncipherment, keyCertSign
EOF

openssl genrsa \
  -out "${FOLDER}/ca.key" \
  4096

openssl req \
  -new \
  -key "${FOLDER}/ca.key" \
  -config "${FOLDER}/ca.cnf" \
  -out "${FOLDER}/ca.csr"

openssl x509 \
  -req \
  -days 365 \
  -signkey "${FOLDER}/ca.key" \
  -extensions req_ext \
  -extfile "${FOLDER}/ca.cnf" \
  -in "${FOLDER}/ca.csr" \
  -out "${FOLDER}/ca.crt"

cat >"${FOLDER}/tsb_certs.cnf" <<EOF
# all the fields in this CNF are just example, Client should follow its own PKI practice to configue it properly
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
commonName          = Example TSB Envoy GUI
[ req_ext ]
subjectKeyIdentifier = hash
basicConstraints     = critical, CA:false
keyUsage             = digitalSignature, keyEncipherment
extendedKeyUsage     = serverAuth, clientAuth
subjectAltName       = @alt_names
[ alt_names ]
DNS.1 = ${TSB_FQDN}
EOF


create_cert tsb_certs \
  "${FOLDER}" \
  "${FOLDER}/tsb_certs.cnf" \
  "${FOLDER}/ca.crt" \
  "${FOLDER}/ca.key" 
  
cat >"${FOLDER}/xcp-central-cert.cnf" <<EOF
# fields for 'req_distinguished_name' in this CNF are just example
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
commonName          = XCP Central
# you will have to use 'extendedKeyUsage = serverAuth, clientAuth' because it will be checked by the TSB.
[ req_ext ]
basicConstraints = critical, CA:false
keyUsage         = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName   = @alt_names
# you will have to use the following DNS name and URI because it will be checked by the TSB
[ alt_names ]
DNS.1 = xcp.tetrate.io
URI.1 = spiffe://xcp.tetrate.io/central
DNS.2 = ${TSB_FQDN}
DNS.3 = ${TSB_FQDN}:9443
EOF

create_cert xcp-central-cert \
  "${FOLDER}" \
  "${FOLDER}/xcp-central-cert.cnf" \
  "${FOLDER}/ca.crt" \
  "${FOLDER}/ca.key"  

ssh-keygen -f jwt-token.key -m pem  -q -N ""
#kubectl -n tsb create secret generic iam-signing-key --from-file=private.key=jwt-token.key