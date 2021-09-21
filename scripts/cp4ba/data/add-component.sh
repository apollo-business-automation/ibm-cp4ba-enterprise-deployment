#!/bin/bash
CR_PATH=$1
COMPONENT=$2
SC_OPTIONAL_COMPONENTS=`yq r $CR_PATH spec.shared_configuration.sc_optional_components`
if [ -z "$SC_OPTIONAL_COMPONENTS" ]
  then
    yq w -i $CR_PATH spec.shared_configuration.sc_optional_components "$COMPONENT"
    echo "Component $2 set to spec.shared_configuration.sc_optional_components"
elif [[ $SC_OPTIONAL_COMPONENTS =~ ^${COMPONENT}$|,${COMPONENT},|,${COMPONENT}$|^${COMPONENT}, ]]
  then
    echo "Component $2 is already present in the CR"    
else
  yq w -i $CR_PATH spec.shared_configuration.sc_optional_components "$SC_OPTIONAL_COMPONENTS,$COMPONENT"
  echo "Component $2 appended to spec.shared_configuration.sc_optional_components"
fi
