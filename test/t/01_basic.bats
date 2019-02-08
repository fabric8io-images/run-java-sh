#!/usr/bin/env bats

load environment
load test_helper

@test "No JAR or main class found" {

  JAVA_APP_DIR=$RUN_JAVA_DIR run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_regexp "^ERROR"
  assert_regexp "$RUN_JAVA_DIR"
  assert_regexp "JAVA_MAIN_CLASS.*JAVA_APP_JAR"
  assert_regexp "0 found"
  assert_status 1
}

@test "More than 1 one main JAR found" {
  d=$(mktmpdir "2jars")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  cp "$TEST_JAR_DIR/test.jar" "$d/test2.jar"
  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_regexp "^ERROR"
  assert_regexp "$d"
  assert_regexp "JAVA_MAIN_CLASS.*JAVA_APP_JAR"
  assert_regexp "2 found"
  assert_status 1
}

@test "Exact one JAR found (with arg)" {
  d=$(mktmpdir "1jar")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA run --user roland
  echo $status
  echo $output

  assert_jvmarg "-XX:\+UseParallelGC"
  assert_jvmarg "-XX:GCTimeRatio=4"
  assert_jvmarg "-XX:AdaptiveSizePolicyWeight=90"
  assert_jvmarg "-XX:\+ExitOnOutOfMemoryError"
  assert_jvmarg "-XX:MinHeapFreeRatio=20"
  assert_jvmarg "-XX:MaxHeapFreeRatio=40"

  assert_command_contains "-cp ."
  assert_command_contains "-jar $d/test.jar"
  assert_command_contains_not "TestMain"

  assert_arg "--user"
  assert_arg "roland"

  assert_status 0
}

@test "Exact one WAR found (with arg)" {
  d=$(mktmpdir "1war")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.war"
  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA run --user roland
  echo $status
  echo $output

  assert_jvmarg "-XX:\+UseParallelGC"
  assert_jvmarg "-XX:GCTimeRatio=4"
  assert_jvmarg "-XX:AdaptiveSizePolicyWeight=90"
  assert_jvmarg "-XX:\+ExitOnOutOfMemoryError"
  assert_jvmarg "-XX:MinHeapFreeRatio=20"
  assert_jvmarg "-XX:MaxHeapFreeRatio=40"

  assert_command_contains "-cp ."
  assert_command_contains "-jar $d/test.war"
  assert_command_contains_not "TestMain"

  assert_arg "--user"
  assert_arg "roland"

  assert_status 0
}

@test "Exact one JAR found but without JAVA_MAIN_CLASS and manifest entry" {
  d=$(mktmpdir "1jar-without-manifest")
  cp "$TEST_JAR_DIR/test-without-manifest-entry.jar" "$d/test.jar"
  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_regexp "no main manifest"
  assert_status 1
}

@test "Exact one JAR without manifest entry but JAVA_MAIN_CLASS" {
  d=$(mktmpdir "1jar-without-manifest-mainclass")
  cp "$TEST_JAR_DIR/test-without-manifest-entry.jar" "$d/test.jar"
  JAVA_APP_DIR=$d JAVA_MAIN_CLASS=TestMain run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_command_contains "TestMain"
  assert_command_contains "-cp .:$d"
  assert_status 0
}

@test "JAVA_APP_NAME set" {
  d=$(mktmpdir "java-appname")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  JAVA_APP_DIR=$d JAVA_APP_NAME="ghandi" run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_env JAVA_APP_NAME ghandi
  set +e
  eval "$TEST_SHELL -c 'exec -a test true 2>/dev/null'"
  local rc=$?
  set -e
  if [ $rc -eq 0 ]; then
    assert_ps ghandi
  fi
  assert_status 0
}

@test "JAVA_MAIN_CLASS with run-classpath without JAVA_APP_JAR" {
  d=$(mktmpdir "mainclass-classpath-without-jar")
  mkdir "$d/classpathdir1" "$d/classpathdir2"
  echo 'classpathdir1/*' >> "$d/classpath"
  echo 'classpathdir2/*' >> "$d/classpath"
  cp "$TEST_JAR_DIR/test.jar" "$d/classpathdir2/test.jar"
  JAVA_APP_DIR=$d JAVA_MAIN_CLASS=TestMain run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_command_contains "TestMain"
  assert_command_contains "-cp .:$d/classpathdir1/*:$d/classpathdir2/*"
  assert_status 0
}