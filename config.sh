set -e
set -x
set -u
SUBJECT_PREFIX="/C=US/ST=California/L=Palo Alto/O=Cloudera/OU=FCE"
KS_PASSWORD="s3cr3t"; export KS_PASSWORD
TS_PASSWORD="changeit"; export TS_PASSWORD
ROOT_CA="rootCA.pem"
ROOT_CA_KEY="rootCA.key"
ROOT_CA_VALIDITY=10950
INTER_CA="interCA.pem"
INTER_CA_KEY="interCA.key"
INTER_CA_CSR="interCA.csr"
INTER_CA_VALIDITY=5475
CERT_VALIDITY=3650
LOAD_BALANCER=mkcluster.vpc.cloudera.com
#JAVA_HOME="/usr/java/jdk1.7.0_67-cloudera"
JAVA_HOME="/usr/java/jdk1.7.0_75-cloudera"
#JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk1.8.0_31.jdk/Contents/Home"
OPENSSL_CONF="/etc/pki/tls/openssl.cnf"
#OPENSSL_CONF="/System/Library/OpenSSL/openssl.cnf"
TEST_SERVER=mktest-ec-1.vpc.cloudera.com
TEST_PORT=45600
UMASK=$(umask)
