#!/usr/bin/env bats

load environment
load test_helper

@test "No proxy settings" {
  d=$(mktmpdir "proxy")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_command_contains_not "http.proxyHost"
  assert_command_contains_not "http.proxyPort"
  assert_command_contains_not "https.proxyHost"
  assert_command_contains_not "https.proxyHost"

  assert_status 0
}

@test "HTTP_PROXY setting" {
  d=$(mktmpdir "proxy")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  HTTP_PROXY=http://proxy:3128 JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttp.proxyHost=proxy -Dhttp.proxyPort=3128"
  assert_command_contains_not "https.proxyHost"
  assert_command_contains_not "https.proxyHost"

  assert_status 0
}

@test "HTTPS_PROXY setting" {
  d=$(mktmpdir "proxy")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  HTTPS_PROXY=https://proxy:4128 JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttps.proxyHost=proxy -Dhttps.proxyPort=4128"
  assert_command_contains_not "http.proxyHost"
  assert_command_contains_not "http.proxyHost"

  assert_status 0
}

@test "NO_PROXY setting" {
  d=$(mktmpdir "proxy")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  no_proxy='localhost, host.example.com' JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttp.nonProxyHosts=\"localhost\|host.example.com\""
  assert_command_contains_not "http.proxyHost"
  assert_command_contains_not "http.proxyHost"

  assert_status 0
}

@test "NO_PROXY setting with wildcards" {
  d=$(mktmpdir "proxy")

  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  no_proxy='localhost, .example.com' JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttp.nonProxyHosts=\"localhost\|\*.example.com\""
  assert_command_contains_not "http.proxyHost"
  assert_command_contains_not "http.proxyHost"

  assert_status 0
}

@test "NO_PROXY setting with wildcard in first element" {
  d=$(mktmpdir "proxy")

  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  no_proxy='.example.com, localhost,.cluster.local' JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttp.nonProxyHosts=\"\*.example.com\|localhost\|\*.cluster.local\""
  assert_command_contains_not "http.proxyHost"
  assert_command_contains_not "http.proxyHost"

  assert_status 0
}

@test "All proxy settings" {
  d=$(mktmpdir "proxy")
  cp "$TEST_JAR_DIR/test.jar" "$d/test.jar"
  HTTP_PROXY=http://proxy:3128 HTTPS_PROXY=https://proxy:4128 no_proxy='localhost, host.example.com' JAVA_APP_DIR=$d run $TEST_SHELL $RUN_JAVA
  echo $status
  echo $output

  assert_jvmarg "-Dhttp.proxyHost=proxy -Dhttp.proxyPort=3128"
  assert_jvmarg "-Dhttps.proxyHost=proxy -Dhttps.proxyPort=4128"
  assert_jvmarg "-Dhttp.nonProxyHosts=\"localhost\|host.example.com\""

  assert_status 0
}
