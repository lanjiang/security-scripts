#!/usr/bin/env bash

. ./config.sh

IFS=$'\r\n' GLOBIGNORE='*' command eval 'HOSTS=($(< csr_hosts))'

for host in ${HOSTS[@]};  do
  echo ${host}

  umask 277
  openssl req -nodes -newkey rsa:2048 -sha256 -keyout ${host}.key -out ${host}.csr -subj "${SUBJECT_PREFIX}/CN=${host}" -reqexts v3ext -config <(cat $OPENSSL_CONF <(
cat <<-EOF
[v3ext]
basicConstraints = CA:FALSE
subjectAltName = DNS:${host},DNS:${LOAD_BALANCER}
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
EOF
))
done
