#!/bin/bash

. "$BUILDPACK_TEST_RUNNER_HOME/lib/test_utils".sh

beforeSetUp() {
  TMPDIR=$(mktemp -d)
}

beforeTearDown() {
  rm -r "$TMPDIR"
}

compile_with_fixture() {
  FIXTURE_DIR="$BUILDPACK_HOME/test/fixtures/$1"
  rm -r "$TMPDIR/build" "$TMPDIR/env" "$TMPDIR/cache" 2>/dev/null || true
  cp -r "$FIXTURE_DIR/build" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/build"
  cp -r "$FIXTURE_DIR/cache" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/cache"
  cp -r "$FIXTURE_DIR/env" $TMPDIR 2>/dev/null || mkdir "$TMPDIR/env"
  capture "$BUILDPACK_HOME/bin/compile" "$TMPDIR/build" "$TMPDIR/cache" "$TMPDIR/env"
  export_env_dir $1
}

export_env_dir() {
  env_dir=$1
  whitelist_regex=${2:-''}
  blacklist_regex=${3:-'^(PATH|GIT_DIR|CPATH|CPPATH|LD_PRELOAD|LIBRARY_PATH)$'}
  FIXTURES_DIR="$BUILDPACK_HOME/test/fixtures/$1/env"
  echo "ENV: "
  echo $(ls $FIXTURES_DIR)
  for e in $(ls $FIXTURES_DIR); do
    echo "$e" | grep -E "$whitelist_regex" | grep -qvE "$blacklist_regex" &&
    export "$e=$(cat $BUILDPACK_HOME/test/fixtures/$1/env/$e)"
    :
  done
}

capture_profile_d_export_script() {
  capture "$TMPDIR/build/.profile.d/export_ejson_secrets.sh"
}

test_simple() {
  compile_with_fixture simple
  assertCapturedSuccess
  assertCaptured "Installing ejson"
  assertCaptured "Loading keypair from environment variables"

  capture_profile_d_export_script
  assertCapturedSuccess
  assertCaptured "Decrypting config.ejson"
  assertCaptured "Done. Decrypted config.ejson"
}

test_missing_public_key() {
  compile_with_fixture missing_public_key
  assertCapturedError
  assertCaptured "Loading keypair from environment variables"
  assertCaptured 'EJSON_PUBLIC_KEY is undefined; make sure EJSON_PUBLIC_KEY and EJSON_PRIVATE_KEY and EJSON_FILE are set'
}

test_missing_private_key() {
  compile_with_fixture missing_private_key
  assertCapturedError
  assertCaptured "Loading keypair from environment variables"
  assertCaptured 'EJSON_PRIVATE_KEY is undefined; make sure EJSON_PUBLIC_KEY and EJSON_PRIVATE_KEY and EJSON_FILE are set'
}

test_missing_ejson_file() {
  compile_with_fixture missing_ejson_file
  assertCapturedError
  assertCaptured "Loading keypair from environment variables"
  assertCaptured 'EJSON_FILE is undefined; make sure EJSON_PUBLIC_KEY and EJSON_PRIVATE_KEY and EJSON_FILE are set'
}

test_ejson_file_not_found_in_build_dir() {
  compile_with_fixture missing_ejson_file_in_build
  assertCaptured "Loading keypair from environment variables"
  capture_profile_d_export_script
  assertCapturedError
  assertCaptured "EJSON_FILE could not be found at config.ejson"
}

test_bad_keypair() {
  compile_with_fixture bad_keypair
  assertCaptured "Loading keypair from environment variables"
  capture_profile_d_export_script
  assertCaptured "Decrypting config.ejson"
  assertCapturedError
  assertCaptured "Decryption failed: couldn't decrypt message"
}
