#!/bin/bash

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>Tooling install started"

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>$(print_timestamp) Install Python3 package"
  yum install python3 -y
  exit_test $? "Install Python3 Failed"

  echo
  echo ">>>>$(print_timestamp) Install Python3 Pip package"
  yum install python3-pip -y
  exit_test $? "Install Python3 Pip Failed"

  echo
  echo ">>>>$(print_timestamp) Setup Pip"
  pip3 install --upgrade setuptools	--user
  exit_test $? "Setup Pip setuptools Failed"
  pip3 install --upgrade pip --user
  exit_test $? "Setup Pip upgrade Failed"

  echo
  echo ">>>>$(print_timestamp) Install pip package wheel"
  pip3 install --user wheel
  exit_test $? "Install pip package wheel failed"

  PATH=`python3 -m site --user-base`/bin:$PATH

  echo
  echo ">>>>$(print_timestamp) Install pip package ansible"
  pip3 install ansible-core==2.12.2 --user
  exit_test $? "Install pip package ansible failed"
fi

echo
echo ">>>>$(print_timestamp) Install pip package openshift"
pip3 install --user openshift
exit_test $? "Install pip package openshift failed"

echo
echo ">>>>$(print_timestamp) Install pip package jmespath"
pip3 install --user jmespath
exit_test $? "Install pip package jmespath failed"

echo
echo ">>>>$(print_timestamp) Install required ansible modules"
for i in {30..1}; do \
  if ansible-galaxy collection install -r ../requirements.yml ; then \
    break; \
  elif [ $i -gt 1 ]; then \
    sleep 1; \
  else \
    echo ">>>>$(print_timestamp) Install required ansible modules fallback to git repos"
    if ansible-galaxy collection install -r ../requirements_git.yml --force; then \
      break; \
    else \
      exit 1; \
    fi
  fi; \
done 
exit_test $? "Install required ansible modules failed"

echo
echo ">>>>$(print_timestamp) Install Git"
yum install git -y
exit_test $? "Install of Git Failed"

echo
echo ">>>>$(print_timestamp) Install helm"
curl -O https://get.helm.sh/helm-v3.6.0-linux-amd64.tar.gz
exit_test $? "Download helm Failed"
tar -zxvf helm-v3.6.0-linux-amd64.tar.gz linux-amd64/helm
mv linux-amd64/helm helm
chmod u+x helm
./helm version
exit_test $? "helm setup Failed"
sleep 5

echo
echo ">>>>$(print_timestamp) Install OpenJDK to provide keytool"
curl -O https://download.java.net/java/GA/jdk9/9/binaries/openjdk-9_linux-x64_bin.tar.gz
exit_test $? "Download OpenJDK Failed"
tar -xvf openjdk-9_linux-x64_bin.tar.gz
ln -fs jdk-9/bin/java java
ln -fs jdk-9/bin/javac javac
ln -fs jdk-9/bin/keytool keytool
if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  ln -fs /usr/ibm-cp4ba-enterprise-deployment/scripts/tooling/jdk-9/bin/java /usr/bin/java
fi
jdk-9/bin/java -version
exit_test $? "OpenJDK setup Failed"

echo
echo ">>>>$(print_timestamp) Tooling install completed"
