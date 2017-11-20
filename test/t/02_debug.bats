#!/usr/bin/env bats

load environment
load test_helper

@test "JAVA_ENABLE_DEBUG set" {
  check_enable_debug JAVA_ENABLE_DEBUG
}

@test "JAVA_DEBUG_ENABLE set" {
  check_enable_debug JAVA_DEBUG_ENABLE
}

@test "JAVA_DEBUG set" {
  check_enable_debug JAVA_DEBUG
}

@test "JAVA_DEBUG_PORT set to 8008" {
  check_enable_debug JAVA_DEBUG 8008
}

@test "JAVA_DEBUG_SUSPEND on" {
  d=$(mktmpdir "debug_suspend_on")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  #JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=true run $TEST_SHELL $RUN_JAVA

  create_test_include_script "$d/debug_suspend_on.sh" $RUN_JAVA
  JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=true JAVA_APP_DIR="$d" run $TEST_SHELL "$d/debug_suspend_on.sh"

  echo $output | tail -n1

  assert_regexp "suspend=y"
  assert_status 0
}

@test "JAVA_DEBUG_SUSPEND false|n|no|0" {
  d=$(mktmpdir "debug_suspend")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  for i in false n no 0
  do
    create_test_include_script "$d/$i.sh" $RUN_JAVA
    JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=$i JAVA_APP_DIR="$d" run $TEST_SHELL "$d/$i.sh"
    echo $output | tail -n1
    assert_regexp "suspend=n"
    assert_status 0
  done
}


check_enable_debug() {
  envvar=$1
  port=$2
  susp=$3
  d=$(mktmpdir $envvar)
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  port_expected=5005
  if [ -n "$port" ]; then
    port_env="JAVA_DEBUG_PORT=$port"
    port_expected=$port
  fi
  eval "JAVA_APP_DIR=$d ${envvar}=true $port_env run $TEST_SHELL $RUN_JAVA"
  echo $status
  echo $output | tail -n1

  assert_jvmarg "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$port_expected"
  assert_regexp "Listening for transport"

  assert_status 0
}
