#!/bin/bash

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>Copy variables.sh"
  cp /config/variables.yml variables.yml
fi

# if [[ $CONTAINER_RUN_MODE == "true" ]]; then
#   if [[ $GLOBAL_CA_PROVIDED == "true" ]]; then
#     echo
#     echo ">>>>Copy Global CA files"  
#     cp /config/global-ca.crt global-ca/global-ca.crt
#     cp /config/global-ca.key global-ca/global-ca.key
#   fi
# fi

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
echo "PATH=`python3 -m site --user-base`:$PATH" >> ~/.bash_profile
echo "export PATH" >> ~/.bash_profile

echo
echo ">>>>Update HOME to internal folder"
echo "HOME=`pwd`" >> ~/.bash_profile
echo "export HOME" >> ~/.bash_profile

echo
echo ">>>>Add aliases"
echo "alias ll='ls -la'" >> ~/.bash_profile
