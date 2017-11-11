#!/bin/sh

rc=0
RUN_JAVA_DIR=${RUN_JAVA_DIR:-/opt/run-java-sh}
REPORT_DIR=${REPORT_DIR:-/opt/reports}
if [ ! -d ${REPORT_DIR}/tap ]; then
  mkdir -p ${REPORT_DIR}/tap  
fi
for shell in bash sh ksh dash ash
do
  echo -n "$shell:\t\t"
  TEST_SHELL="$shell" bats "$RUN_JAVA_DIR/test/t" > ${REPORT_DIR}/tap/$shell.tap
  if [ $? -gt 0 ]; then
    echo "\e[31mERROR\e[0m"
    rc=$?
  else
    echo "\e[32mOK\e[0m"
  fi
done
exit $rc
