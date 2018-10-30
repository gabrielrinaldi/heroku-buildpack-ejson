#!/bin/bash

set -o pipefail

heading() {
  echo "----->" $@;
}

APP_DIR=$(cd $(dirname "${BASH_SOURCE[0]}"); cd ..; pwd)
BIN_DIR="$APP_DIR/vendor/bin"

decrypt_ejson_file() {
  echo $EJSON_PRIVATE_KEY | \
    $BIN_DIR/ejson decrypt --key-from-stdin "$APP_DIR/$EJSON_FILE" 2>&1
}

json_to_export_lines() {
  $BIN_DIR/jq -r 'to_entries|map("export \(.key)=\(.value|tojson)")[]' 2>&1 | \
    grep -v '^export _public_key='
}

ejson_exports() {
  decrypt_ejson_file | \
    json_to_export_lines | \
    while IFS=$'\n' read -r line
    do
      echo $line
    done
}

export_ejson_secrets() {
  exports=$(ejson_exports)
  return_status=$?

  if [ $return_status -eq 0 ]; then
    eval "$exports"
  else
    # re-execute decryption to get failure message then display
    decryption_output=$(decrypt_ejson_file)
    # make sure it's still not successful this time
    if [ $? -ne 0 ]; then
      heading "$decryption_output"
    fi
  fi

  return $return_status
}
