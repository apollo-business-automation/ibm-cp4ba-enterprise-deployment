#!/bin/bash

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>Copy variables.yml"
  cp /config/variables.yml variables.yml
fi

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  if [[ $GLOBAL_CA_PROVIDED == "true" ]]; then
    echo
    echo ">>>>Copy Global CA files"  
    cp /config/global-ca.crt /tmp/global-ca/global-ca.crt
    cp /config/global-ca.key /tmp/global-ca/global-ca.key
  fi
fi

find . -type f \( -iname \*.sh \) | xargs chmod u+x

echo
echo ">>>>Source functions"
. functions.sh

echo
echo ">>>>Update HOME to internal folder"
echo "HOME=`pwd`" >> ~/.bash_profile
echo "export HOME" >> ~/.bash_profile
ORIGINAL_HOME=$HOME
# Set HOME now to set context for Python packages install via Pip in tooling
HOME=`pwd`

cd tooling
./install.sh
exit_test $? "Install Tooling Failed"
cd ..

echo
echo ">>>>Update PATH to include new tooling"
REAL_PATH=`realpath tooling`
echo "PATH=`python3 -m site --user-base`/bin:$REAL_PATH:$PATH" >> $ORIGINAL_HOME/.bash_profile
echo "export PATH" >> $ORIGINAL_HOME/.bash_profile

echo
echo ">>>>Add aliases"
echo "alias ll='ls -la'" >> $ORIGINAL_HOME/.bash_profile
