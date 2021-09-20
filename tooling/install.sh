#!/bin/bash

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Tooling install started"

echo
echo ">>>>$(print_timestamp) Install OpenJDK to provide keytool"
curl -O https://download.java.net/java/GA/jdk9/9/binaries/openjdk-9_linux-x64_bin.tar.gz
exit_test $? "Download OpenJDK to provide keytool Failed"
tar -xvf openjdk-9_linux-x64_bin.tar.gz
ln -fs jdk-9/bin/java java
ln -fs jdk-9/bin/javac javac
ln -fs jdk-9/bin/keytool keytool

echo
echo ">>>>$(print_timestamp) Install jq"
curl -L -o jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux32
exit_test $? "Download jq Failed"
chmod u+x jq

echo
echo ">>>>$(print_timestamp) Install yq"
curl -L -o yq https://github.com/mikefarah/yq/releases/download/3.4.1/yq_linux_amd64
exit_test $? "Download yq Failed"
chmod u+x yq

echo
echo ">>>>$(print_timestamp) Install oc"
curl -k https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/openshift-client-linux.tar.gz --output oc.tar
exit_test $? "Download oc Failed"
tar -xvf oc.tar oc
chmod u+x oc

echo
echo ">>>>$(print_timestamp) Install helm"
curl -O https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
exit_test $? "Download helm Failed"
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz linux-amd64/helm
mv linux-amd64/helm helm
chmod u+x helm

echo
echo ">>>>$(print_timestamp) Install maven"
curl -k -O https://dlcdn.apache.org/maven/maven-3/3.8.2/binaries/apache-maven-3.8.2-bin.tar.gz
exit_test $? "Download maven Failed"
tar -xvf apache-maven-3.8.2-bin.tar.gz
ln -fs apache-maven-3.8.2/bin/mvn mvn

echo
echo ">>>>$(print_timestamp) Tooling install completed"
