#!/bin/bash

set -o pipefail

heading() {
  echo "----->" $@;
}

APP_DIR=$(cd $(dirname "${BASH_SOURCE[0]}"); cd ..; pwd)

decrypt_ejson_file() {
  echo $EJSON_PRIVATE_KEY | ejson2env --key-from-stdin "$APP_DIR/$EJSON_FILE" 2>&1
}

export_ejson_secrets() {
  decrypt_ejson_file > /tmp/ejson_env.sh
  return_status=$?

  if [ $return_status -eq 0 ]; then
    source /tmp/ejson_env.sh
    rm /tmp/ejson_env.sh
  else
    # re-execute decryption to get failure message then display
    decryption_output=$(decrypt_ejson_file)
    # make sure it's still not successful this time
    if [ $? -ne 0 ]; then
      heading "EJSON decryption failed:"
      heading "$decryption_output"
    fi
  fi

  return $return_status
}

save_ejson_secrets() {
  decrypt_ejson_file > /tmp/ejson_env.sh
  return_status=$?

  if [ $return_status -ne 0 ]; then
    # re-execute decryption to get failure message then display
    decryption_output=$(decrypt_ejson_file)
    # make sure it's still not successful this time
    if [ $? -ne 0 ]; then
      heading "EJSON decryption failed:"
      heading "$decryption_output"
    fi
  fi

  return $return_status
}

if [[ "$EJSON_AUTO_EXPORT" == "true" ]]; then
  export_ejson_secrets
fi
