#!/usr/bin/env bats

load environment
load test_helper

@test "CONTAINER_MAX_MEMORY set" {
  d=$(mktmpdir "maxmem")
  create_test_include_script "$d/mem_test.sh" 'echo $CONTAINER_MAX_MEMORY' $MATH_FUNCTIONS $CONTAINER_LIMITS
  run $TEST_SHELL $d/mem_test.sh
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
  create_test_include_script "$d/cpus_test.sh" 'echo $CONTAINER_CORE_LIMIT' $MATH_FUNCTIONS $CONTAINER_LIMITS
  run $TEST_SHELL $d/cpus_test.sh
  echo "Status: $status"
  echo "CPUs detected: $output"
  echo "CPUs given: $CPUS"
  
  if [ -n "${CPUS:-}" ]; then
    given_cpus=$(ceiling ${CPUS})
    detected_cpus=$output
    [ $given_cpus -eq $detected_cpus ]
  fi
  assert_status 0  
}
