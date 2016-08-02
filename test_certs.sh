#!/usr/bin/env bash

. ./config.sh

# To check cert chain
echo "Cert chain check"
openssl verify -CAfile $ROOT_CA -untrusted $INTER_CA ${TEST_SERVER}.pem

# To check if the csr,cert and private key all uses the same public/private keys
echo "Key check"
openssl rsa -modulus -in ${TEST_SERVER}.key -noout | md5sum
openssl req -modulus -in ${TEST_SERVER}.csr -noout | md5sum
openssl x509 -modulus -in ${TEST_SERVER}.pem -noout | md5sum

# Test server cert with PEM truststore
echo "Test server cert with PEM truststore, Enter Ctrl-D to quit after the cert is verified"
${JAVA_HOME}/bin/java -cp . -Djavax.net.ssl.keyStore=${TEST_SERVER}.jks -Djavax.net.ssl.keyStorePassword=$KS_PASSWORD -Djava.protocol.handler.pkgs=com.sun.net.ssl.internal.www.protocol -Djavax.net.debug=ssl SSLEchoServer $TEST_PORT &
sleep 3
openssl s_client -showcerts -CAfile ca-certs.pem -connect ${TEST_SERVER}:${TEST_PORT}

# Test server cert with JKS truststore (In the directory from where it is run, copy the truststore file with filename jssecacerts)
echo "Test server cert with JKS truststore, Enter q to quit after the cert is verified"
${JAVA_HOME}/bin/java -cp . -Djavax.net.ssl.keyStore=${TEST_SERVER}.jks -Djavax.net.ssl.keyStorePassword=$KS_PASSWORD -Djava.protocol.handler.pkgs=com.sun.net.ssl.internal.www.protocol -Djavax.net.debug=ssl SSLEchoServer $TEST_PORT &
sleep 3
${JAVA_HOME}/bin/java -cp . InstallCert ${TEST_SERVER}:${TEST_PORT}
