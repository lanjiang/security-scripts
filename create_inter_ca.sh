#!/usr/bin/env bash

. ./config.sh

umask 277
openssl req -nodes -newkey rsa:2048 -keyout $INTER_CA_KEY -out $INTER_CA_CSR -subj "${SUBJECT_PREFIX}/CN=InterCA" -config $OPENSSL_CONF
umask 222
openssl x509 -req -sha256 -extensions v3ext -in $INTER_CA_CSR -CA $ROOT_CA -CAkey $ROOT_CA_KEY -CAcreateserial -out $INTER_CA -days $INTER_CA_VALIDITY -extfile <(
cat <<-EOF
[v3ext]
basicConstraints = critical,CA:TRUE, pathlen:0
keyUsage = critical, keyCertSign, cRLSign
EOF
)
