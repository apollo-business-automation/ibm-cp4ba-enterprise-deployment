#!/bin/bash

if [[ $CONTAINER_RUN_MODE == "true" ]]; then
  echo
  echo ">>>>Copy variables.sh"
  cp /config/variables.sh variables.sh
fi

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
PATH=`realpath tooling`:$PATH

echo
echo ">>>>Update HOME to internal folder"
HOME=`pwd`


if [[ $ACTION == "install" ]]; then
  echo
  echo ">>>>Starting install action"

  echo
  echo ">>>>Configure automagic resiliency with PodDisruptionBudget"
  oc project automagic
  oc apply -f automagic/poddisruptionbudget.yaml

  cd storage-class
  ./make-default.sh
  cd ..

  if [[ $CONTAINER_RUN_MODE == "true" ]]; then
    ./install.sh
    exit $?
  else
    nohup ./install.sh &> nohup_install.log &
    sleep 1
    tail -f nohup_install.log
  fi

fi

if [[ $ACTION == "remove" ]]; then
  echo
  echo ">>>>Starting remove action"
  if [[ $CONTAINER_RUN_MODE == "true" ]]; then
    ./remove.sh
    exit $?
  else
    nohup ./remove.sh &> nohup_remove.log &
    sleep 1
    tail -f nohup_remove.log
  fi    
fi
