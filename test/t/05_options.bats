#!/usr/bin/env bats


load environment
load test_helper

@test "options command - all" {
  JAVA_APP_DIR=$RUN_JAVA_DIR run $TEST_SHELL $RUN_JAVA options
  echo $status
  echo $output

  if [ -n "${MEMORY:-}" ]; then
      if [ $(java_version) -lt 10 ]; then
        assert_regexp "-Xmx"
      else
        assert_not_regexp "-Xmx"
      fi
      assert_not_regexp "-Xms"
  fi
  if [ -n "${CPUS}" ]; then
    assert_regexp "CICompilerCount"
  fi
  assert_status 0
}

@test "options command - memory" {
  JAVA_APP_DIR=$RUN_JAVA_DIR JAVA_INIT_MEM_RATIO=50 run $TEST_SHELL $RUN_JAVA options --memory
  echo $status
  echo $output

  if [ -n "${MEMORY:-}" ]; then
    if [ $(java_version) -lt 10 ]; then
      assert_regexp "-Xmx"
    else
      assert_not_regexp "-Xmx"
    fi
    assert_regexp "-Xms"
  fi
  if [ -n "${CPUS}" ]; then
    assert_not_regexp "CICompilerCount"
  fi
  assert_status 0
}
