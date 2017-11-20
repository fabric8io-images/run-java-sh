#!/usr/bin/env bats

load environment
load test_helper

@test "CONTAINER_MAX_MEMORY set" {
  d=$(mktmpdir "maxmem")

  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_test_include_script "$d/mem_test.sh" $RUN_JAVA 'echo ${CONTAINER_MAX_MEMORY:-}'
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/mem_test.sh

  local result=$(echo "$output" | tail -n1)

  echo "Status: $status"
  echo "Memory detected: $result"
  echo "Memory given: $MEMORY"

  if [ -n "${MEMORY:-}" ]; then
    given_mem=$(echo $MEMORY | awk '{printf "%d\n", $1 * 1024 * 1024}')
    detected_mem=$result
    [ $given_mem -eq $detected_mem ]
  fi
  assert_status 0
}

@test "CONTAINER_CORE_LIMIT set" {
  d=$(mktmpdir "maxcpus")

  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_test_include_script "$d/cpus_test.sh" $RUN_JAVA 'echo ${CONTAINER_CORE_LIMIT:-}'
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/cpus_test.sh

  local result=$(echo "$output" | tail -n1)

  echo "Status: $status"
  echo "CPUs detected: $result"
  echo "CPUs given: $CPUS"

  if [ -n "${CPUS:-}" ]; then
    given_cpus=$(ceiling ${CPUS})
    detected_cpus=$result
    [ $given_cpus -eq $detected_cpus ]
  fi
  assert_status 0
}
