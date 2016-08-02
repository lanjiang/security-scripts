#!/usr/bin/env bash

. ./config.sh

IFS=$'\r\n' GLOBIGNORE='*' command eval 'HOSTS=($(< csr_hosts))'
cat /dev/null > index.txt

for host in ${HOSTS[@]};  do
  openssl ca -batch -md sha256 -in ${host}.csr -out ${host}.pem -cert $INTER_CA -keyfile $INTER_CA_KEY -create_serial -days $CERT_VALIDITY -config <(cat $OPENSSL_CONF <(
cat <<-EOF
[ CA_default ]
dir = .
new_certs_dir = .
database = index.txt
serial = rootCA.srl
x509_extensions = server_cert
copy_extensions = copy
[ server_cert ]
basicConstraints = critical,CA:FALSE
extendedKeyUsage = serverAuth, clientAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
EOF
))
#  openssl x509 -req -sha256 -extensions v3ext -in ${host}.csr -CA $INTER_CA -CAkey $INTER_CA_KEY -CAcreateserial -out ${host}.pem -days $CERT_VALIDITY -extfile <(
#cat <<-EOF
#[v3ext]
#basicConstraints = CA:FALSE
#subjectAltName = DNS:copy
#keyUsage = digitalSignature, keyEncipherment
#extendedKeyUsage = serverAuth, clientAuth
#EOF
#)

  # Add Intermediate CA to server PEM
  cat $INTER_CA >> ${host}.pem
  
  umask 277
  openssl pkcs12 -export -in ${host}.pem -inkey ${host}.key -out ${host}.pfx -passout env:KS_PASSWORD

  ${JAVA_HOME}/bin/keytool -importkeystore -destkeystore ${host}.jks -srckeystore ${host}.pfx -srcstoretype PKCS12 -srcstorepass ${KS_PASSWORD} -deststorepass ${KS_PASSWORD}

  rm -f ${host}.pfx
  umask $UMASK
done
