#!/usr/bin/env bats


load environment
load test_helper

@test "CONTAINER_MAX_MEMORY set" {
  d=$(mktmpdir "maxmem")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_non_exec_run_script "$d/mem_test.sh" 'echo ${CONTAINER_MAX_MEMORY:-}'
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/mem_test.sh
  local result=$(echo "$output" | tail -n1)
  echo "Status: $status"
  echo $output
  echo "Memory detected: $result"
  echo "Memory given: $MEMORY"

  if [ -n "${MEMORY:-}" ]; then
    given_mem=$(echo $MEMORY | awk '{printf "%d\n", $1 * 1024 * 1024}')
    detected_mem=$result
    [ $given_mem -eq $detected_mem ]
  fi
  assert_status 0
}

@test "No mem opts when JAVA_MAX_MEM_RATIO is set to 0" {
  if [ -n "$MEMORY" ]; then
    JAVA_MAX_MEM_RATIO="0" run $TEST_SHELL $RUN_JAVA options
    echo $output
    assert_not_regexp "-Xmx"
    assert_status 0
  fi
}

@test "Default max mem ratio" {
  if [ -n "$MEMORY" ]; then
    run $TEST_SHELL $RUN_JAVA options
    echo $output
    if [ $(java_version) -lt 10 ]; then
      assert_regexp "-Xmx"
    else
      assert_not_regexp "-Xmx"
    fi
    assert_status 0
  fi
}

@test "CONTAINER_CORE_LIMIT set" {
  d=$(mktmpdir "maxcpus")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_non_exec_run_script "$d/cpus_test.sh" 'echo ${CONTAINER_CORE_LIMIT:-}'
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/cpus_test.sh
  local result=$(echo "$output" | tail -n1)
  echo $output
  echo "Status: $status"
  echo "CPUs detected: $result"

  if [ -n "${CPUS:-}" ]; then
    given_cpus=$(ceiling ${CPUS})
    echo "CPUs given: $given_cpus"
    detected_cpus=$result
    [ $given_cpus -eq $detected_cpus ]
  fi
  assert_status 0
}
