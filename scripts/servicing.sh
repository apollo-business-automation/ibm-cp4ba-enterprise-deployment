#!/bin/bash

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>Copy variables.sh"
  cp /config/variables.sh variables.sh
fi

echo
echo ">>>>Source internal variables"
. inernal-variables.sh

echo
echo ">>>>Source variables"
. variables.sh

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  if [[ $GLOBAL_CA_PROVIDED == "true" ]]; then
    echo
    echo ">>>>Copy Global CA files"  
    cp /config/global-ca.crt global-ca/global-ca.crt
    cp /config/global-ca.key global-ca/global-ca.key
  fi
fi

find . -type f \( -iname \*.sh \) | xargs chmod u+x

echo
echo ">>>>Source functions"
. functions.sh

cd tooling
./install.sh
exit_test $? "Install Tooling Failed"
cd ..

echo
echo ">>>>Update PATH to include new tooling"
REAL_PATH=`realpath tooling`
echo "PATH=$REAL_PATH:$PATH" >> ~/.bash_profile
echo "export PATH" >> ~/.bash_profile

echo
echo ">>>>Update HOME to internal folder"
echo "HOME=`pwd`" >> ~/.bash_profile
echo "export HOME" >> ~/.bash_profile

echo
echo ">>>>Add aliases"
echo "alias ll='ls -la'" >> ~/.bash_profile
