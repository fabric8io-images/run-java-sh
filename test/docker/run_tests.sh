#!/bin/bash

worst_rc=0
RUN_JAVA_DIR=${RUN_JAVA_DIR:-/opt/test}
REPORT_DIR=${REPORT_DIR:-${RUN_JAVA_DIR}/reports}
[ -d ${REPORT_DIR} ] || mkdir -p ${REPORT_DIR}

echo "-----------------------------------"
echo "Announcing Java version:"
java -version
echo -e "-----------------------------------\n\n"

for shell in bash sh ksh dash ash
do
  echo -e -n "$shell:\t\t"
  TEST_SHELL="$shell" bats "$RUN_JAVA_DIR/test/t" > ${REPORT_DIR}/${shell}.tap
  rc=$?
  if [ $rc -gt 0 ]; then
    worst_rc=$rc
    echo -e "\e[31mERROR\e[0m"
    [ -d ${REPORT_DIR}/error ] || mkdir -p ${REPORT_DIR}/error 
    cp ${REPORT_DIR}/${shell}.tap ${REPORT_DIR}/error
    echo "------------------------------------------------------"
    cat ${REPORT_DIR}/${shell}.tap
    echo "------------------------------------------------------"    
  else
    echo -e "\e[32mOK\e[0m"
  fi
done
exit $worst_rc
