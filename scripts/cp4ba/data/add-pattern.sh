#!/bin/bash
CR_PATH=$1
PATTERN=$2
SC_DEPLOYMENT_PATTERNS=`yq r $CR_PATH spec.shared_configuration.sc_deployment_patterns`
if [ -z "$SC_DEPLOYMENT_PATTERNS" ]
  then
    yq w -i $CR_PATH spec.shared_configuration.sc_deployment_patterns "$PATTERN"
    echo "Pattern $2 set to spec.shared_configuration.sc_deployment_patterns"
elif [[ $SC_DEPLOYMENT_PATTERNS =~ ^${PATTERN}$|,${PATTERN},|,${PATTERN}$|^${PATTERN},  ]]
  then
    echo "Pattern $2 is already present in the CR"    
else
  yq w -i $CR_PATH spec.shared_configuration.sc_deployment_patterns "$SC_DEPLOYMENT_PATTERNS,$PATTERN"
  echo "Pattern $2 appended to spec.shared_configuration.sc_deployment_patterns"
fi
