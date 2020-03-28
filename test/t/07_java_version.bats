load environment
load test_helper

@test "JAVA_MAJOR_VERSION set" {
  d=$(mktmpdir "javamajorversion")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_non_exec_run_script "$d/javaversion_test.sh" 'echo ${JAVA_MAJOR_VERSION:-}'
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/javaversion_test.sh
  JAVA_APP_DIR="$d" run $TEST_SHELL $d/javaversion_test.sh  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $output
  local result=$(echo "$output" | tail -n1)
  echo "Status: $status"
  echo "JAVA_MAJOR_VERSION: $result"

  # Check that the version is an integer, more than 6
  [ $result -gt 6 ]
  assert_status 0
}
