# security-scripts
Security-related scripts

## Cert scripts
The scripts helps to create a Root CA, an intermediate CA and certs for hosts. The scripts also helps to convert the certs and keys in JKS formats. Finally the scripts also helps to test the certs and truststores.
Before the scripts can be used, the config file config.sh should be customized to the environment. There are two Jave classes that need to be compiled too. Compile the Java classes with the command

    ${JAVA_HOME}/bin/javac SSLEchoServer.java
    ${JAVA_HOME}/bin/javac InstallCert.java

The file csr_hosts should also be customized to list all the hosts for which the certs are required.
### To create the root CA ###
    ./create_root_ca.sh
### To create the intermediate CA ###
    ./create_inter_ca.sh
### To generate the server certs ###
    ./generate_server_csr.sh
### To sign the server certs intermediate CA ###
    ./sign_with_interCA.sh
### To test the keys, certs and truststores ###
    ./test_certs.sh

There are some additional files distributed.

**misc_commands:** Miscellaneous commands to convert the cert formats.

**SSLEchoServer.java:** A simple TLS/SSL Server that uses the server keystore and echoes the data sent to it. To use this

    ${JAVA_HOME}/bin/java -cp . -Djavax.net.ssl.keyStore=${TEST_SERVER}.jks -Djavax.net.ssl.keyStorePassword=$KS_PASSWORD -Djava.protocol.handler.pkgs=com.sun.net.ssl.internal.www.protocol -Djavax.net.debug=ssl SSLEchoServer $TEST_PORT &

**InstallCert.java:** A program that makes a connection to a SSL Server and verifies if the certs sent by the Server is trusted.

    ${JAVA_HOME}/bin/java -cp . InstallCert ${TEST_SERVER}:${TEST_PORT}

## Kerberos scripts
**configure_kerberos.py:** Configure Kerberos using CM API
