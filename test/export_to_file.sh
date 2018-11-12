#!/bin/bash

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  FIXTURES_DIR="$BUILDPACK_HOME/test/fixtures/$1/env"
  for e in $(ls $FIXTURES_DIR); do
    echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
    export "$e=$(cat $BUILDPACK_HOME/test/fixtures/$1/env/$e)"
    :
  done
}
export_env_dir $1

. "$TMPDIR/build/.profile.d/ejson_secrets.sh"
export_ejson_secrets # call buildpack defined function
echo "$foo" > "$TMPDIR/foo"
echo $_public_key > "$TMPDIR/_public_key"
