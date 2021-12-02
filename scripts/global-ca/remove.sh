#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../inernal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Global CA remove started"

echo
echo ">>>>Init env"
. ../init.sh

# Nothing to be done

echo
echo ">>>>$(print_timestamp) Global CA remove completed"
