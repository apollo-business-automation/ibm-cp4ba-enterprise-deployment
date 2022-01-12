#!/bin/bash

echo
echo ">>>>Source internal variables"
. ../internal-variables.sh

echo
echo ">>>>Source variables"
. ../variables.sh

echo
echo ">>>>Source functions"
. ../functions.sh

echo
echo ">>>>$(print_timestamp) Tooling remove started"

# Nothing to do here, tooling is fully local

echo
echo ">>>>$(print_timestamp) Tooling remove completed"
