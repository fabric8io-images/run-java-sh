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
  debug_out=/tmp/debug_suspend_log_$$.output
  JAVA_APP_DIR=$d JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=true $TEST_SHELL -x $RUN_JAVA >$debug_out 2>&1 &
  pid=$!
  sleep 2
  echo $output
  echo "==========="
  cat $debug_out
  echo "==========="
  kill -9 $pid
  
  output=$(cat $debug_out)
  rm $debug_out
  
  assert_regexp "suspend=y"
  sleep 1
}

@test "JAVA_DEBUG_SUSPEND false|n|no|0" {
  d=$(mktmpdir "debug_suspend")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  for i in false n no 0
  do
    JAVA_APP_DIR=$d JAVA_DEBUG=1 JAVA_DEBUG_SUSPEND=$i run $TEST_SHELL $RUN_JAVA
    echo $output
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
  echo $output
  
  assert_jvmarg "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=$port_expected"
  assert_regexp "Listening for transport"

  assert_status 0
}
