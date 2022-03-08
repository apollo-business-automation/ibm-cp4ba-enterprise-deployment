#!/bin/bash

exit_test() {
  local exit_code="${1}"
  local fail_message="${2:-Failed}"

  if [[ "$exit_code" != "0" ]]; then
    echo ">>>>$(print_timestamp) ${fail_message}"
    exit $exit_code
  fi
}

print_timestamp() {
  date --utc +%FT%TZ
}
