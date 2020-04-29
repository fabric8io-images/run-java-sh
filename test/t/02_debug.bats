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
  d=$(mktmpdir "debug_suspend_yes")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"

  create_non_exec_run_script "$d/debug_suspend_on.sh"
  JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=true JAVA_APP_DIR="$d" run $TEST_SHELL "$d/debug_suspend_on.sh"

  echo $output | tail -n1

  assert_regexp "suspend=y"
  sleep 1
}

@test "JAVA_DEBUG_SUSPEND false|n|no|0" {
  d=$(mktmpdir "debug_suspend")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  for i in false n no 0
  do
    create_non_exec_run_script "$d/$i.sh"
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
  if [ $(java_version) -gt 9 ]; then
    port_expected="\\*:${port_expected}"
  fi
  eval "JAVA_APP_DIR=$d ${envvar}=true $port_env run $TEST_SHELL $RUN_JAVA"
  echo $(java_version)
  echo $port_expected
  echo $status
  echo $output | tail -n1

  assert_jvmarg "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$port_expected"
  assert_regexp "Listening for transport"

  assert_status 0
}
