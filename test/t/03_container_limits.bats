#!/usr/bin/env bats


load environment
load test_helper

@test "CONTAINER_MAX_MEMORY set" {
  d=$(mktmpdir "maxmem")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo "Status: $status"
  echo "Memory detected: $output"
  echo "Memory given: $MEMORY"
  
  if [ -n "${MEMORY:-}" ]; then
    given_mem=$(echo $MEMORY | awk '{printf "%d\n", $1 * 1024 * 1024}')
    detected_mem=$output
    [ $given_mem -eq $detected_mem ]
  fi
  assert_status 0
}

@test "CONTAINER_CORE_LIMIT set" {
  d=$(mktmpdir "maxcpus")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo "Status: $status"
  echo "CPUs detected: $output"
  echo "CPUs given: $CPUS"
  
  if [ -n "${CPUS:-}" ]; then
    given_cpus=$(ceiling ${CPUS})
    detected_cpus=$output
    [ $given_cpus -ne $detected_cpus ]
  fi
  assert_status 0  
}
