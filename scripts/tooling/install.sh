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
  pip3 install ansible==2.9.27 --user
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
ansible-galaxy collection install -r ../requirements.yml 
exit_test $? "Install required ansible modules failed"

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
echo ">>>>$(print_timestamp) Tooling install completed"
