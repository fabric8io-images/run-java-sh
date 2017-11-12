#!/bin/sh

rc=0
RUN_JAVA_DIR=${RUN_JAVA_DIR:-/opt/run-java-sh}
REPORT_DIR=${REPORT_DIR:-/opt/reports}
[ -d ${REPORT_DIR} ] || mkdir -p ${REPORT_DIR}
fi
for shell in bash sh ksh dash ash
do
  echo -n "$shell:\t\t"
  TEST_SHELL="$shell" bats "$RUN_JAVA_DIR/test/t" > ${REPORT_DIR}/${shell}.tap
  if [ $? -gt 0 ]; then
    rc=$?
    echo "\e[31mERROR\e[0m"
    [ -d ${REPORT_DIR}/error ] || mkdir -p ${REPORT_DIR}/error 
    cp ${REPORT_DIR}/${shell}.tap ${REPORT_DIR}/error
  else
    echo "\e[32mOK\e[0m"
  fi
done
exit $rc
