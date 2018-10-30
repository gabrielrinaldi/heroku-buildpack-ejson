#!/bin/bash

. "$BUILDPACK_TEST_RUNNER_HOME/lib/test_utils".sh

# use a consistent cache dir to avoid redownloading ejson & jq in each test
CACHETMP=/tmp/heroku-buildpack-ejson-cache-dir
mkdir -p $CACHETMP

beforeSetUp() {
  TMPDIR=$(mktemp -d)
  unset foo
  unset _public_key
}

beforeTearDown() {
  rm -r "$TMPDIR"
}

compile_with_fixture() {
  FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/$1"
  rm -r "$TMPDIR/build" "$TMPDIR/env" 2>/dev/null || true
  cp -r "$FIXTURE_DIR/build" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/build"
  cp -r "$FIXTURE_DIR/cache" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/cache"
  cp -r "$FIXTURE_DIR/env" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/env"
  capture "$BUILDPACK_HOME/bin/compile" "$TMPDIR/build" "$CACHETMP" "$TMPDIR/env"
  export_env_dir $1
}

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

source_profile_d_export_script() {
  source $TMPDIR/build/.profile.d/export_ejson_secrets.sh
}

test_simple() {
  compile_with_fixture simple
  assertCapturedSuccess

  source_profile_d_export_script
  export_ejson_secrets # call buildpack defined function
  assertEquals "Bar's Baz

Hello" "$foo"
  assertEquals "" "$_public_key"
}

test_missing_private_key() {
  compile_with_fixture missing_private_key
  assertCapturedError
  assertCaptured 'EJSON_PRIVATE_KEY is undefined; make sure EJSON_PRIVATE_KEY and EJSON_FILE are set'
}

test_missing_ejson_file() {
  compile_with_fixture missing_ejson_file
  assertCapturedError
  assertCaptured 'EJSON_FILE is undefined; make sure EJSON_PRIVATE_KEY and EJSON_FILE are set'
}

test_ejson_file_not_found_in_build_dir() {
  compile_with_fixture missing_ejson_file_in_build
  assertCapturedError
  assertCaptured "EJSON_FILE could not be found at config.ejson"
}

test_bad_keypair() {
  compile_with_fixture bad_keypair
  assertCapturedError
  assertCaptured "Decryption failed: couldn't decrypt message"
}
