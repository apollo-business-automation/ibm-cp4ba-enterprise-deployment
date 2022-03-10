#!/bin/bash

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>Copy variables.yml"
  cp /config/variables.yml variables.yml
fi

find . -type f \( -iname \*.sh \) | xargs chmod u+x

echo
echo ">>>>Source functions"
. functions.sh

echo
echo ">>>>Update HOME to internal folder"
HOME=`pwd`

cd tooling
./install.sh
exit_test $? "Install Tooling Failed"
cd ..

echo
echo ">>>>Update PATH to include new tooling"
REAL_PATH=`realpath tooling`
PATH=`python3 -m site --user-base`/bin:$REAL_PATH:$PATH

if [[ $ACTION == "install" ]]; then
  echo
  echo ">>>>Starting install action"
  if [[ $CONTAINER_RUN_MODE == "true" ]]; then
    ansible-playbook main.yml -e global_action=install
    status=$?
    exit $status
  else
    nohup ansible-playbook main.yml -e global_action=install &> nohup_install.log &
    sleep 1
    tail -f nohup_install.log
  fi
fi

if [[ $ACTION == "remove" ]]; then
  echo
  echo ">>>>Starting remove action"
  if [[ $CONTAINER_RUN_MODE == "true" ]]; then
    ansible-playbook main.yml -e global_action=remove	
    status=$?
    exit $status
  else
    nohup ansible-playbook main.yml -e global_action=remove &> nohup_remove.log &
    sleep 1
    tail -f nohup_remove.log
  fi    
fi
