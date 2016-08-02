#!/usr/bin/env bash

. ./config.sh

umask 277
openssl genrsa -out $ROOT_CA_KEY 2048
umask $UMASK
openssl req -x509 -new -nodes -sha256 -key $ROOT_CA_KEY -days $ROOT_CA_VALIDITY  -out $ROOT_CA -subj "${SUBJECT_PREFIX}/CN=RootCA" -extensions v3ext -config <(cat $OPENSSL_CONF <(
cat <<-EOF
[v3ext]
basicConstraints = critical,CA:TRUE, pathlen:1
keyUsage = critical, keyCertSign, cRLSign
EOF
))

cp rootCA.pem ca-certs.pem
${JAVA_HOME}/bin/keytool -importcert -noprompt -alias HadoopRootCA -keystore ca-certs.jks -storepass ${TS_PASSWORD} -file $ROOT_CA
cp ${JAVA_HOME}/jre/lib/security/cacerts jssecacerts
${JAVA_HOME}/bin/keytool -importcert -noprompt -alias HadoopRootCA -keystore jssecacerts -storepass changeit -file $ROOT_CA

