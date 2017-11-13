#!/bin/bash

# Script for running tests in a container. This is script is 
# meant to be run *outside* a container and by bind mounting 
# the directory into the container
# 
# Memory and CPU limitations can be given as environment variables:
#
# MEMORY       --memory
# CPUS         --cpus
# CPU_SHARES   --cpus-shares
#
# JDK_TAG      either "openjdk8" or "opendjdk9" for selecting the Java base version
# REPORT_DIR   where to write test reports
# RUN_JAVA_DIR direretory where to find the source

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )
RUN_JAVA_DIR=${RUN_JAVA_DIR:-${base_dir}}
REPORT_DIR=${REPORT_DIR:-${RUN_JAVA_DIR}/reports}
JDK_TAG=${JDK_TAG:-openjdk8}

if [[ ${RUN_JAVA_DIR} != /* ]]; then
  RUN_JAVA_DIR="${base_dir}/${RUN_JAVA_DIR}"
fi

if [[ ${REPORT_DIR} != /* ]]; then
  REPORT_DIR="${base_dir}/${REPORT_DIR}"
fi

run_opts="-e RUN_JAVA_DIR=/opt/test -e REPORT_DIR=/opt/reports"
diag="- JDK:\t\t${JDK_TAG}\n- Report:\t$REPORT_DIR"
if [ -n "${MEMORY}" ]; then
  mem_opts="--memory=$MEMORY --memory-swap=$MEMORY -e MEMORY=$MEMORY"
  diag="$diag\n- Memory:\t$MEMORY"
fi

if [ -n "${CPUS}" ]; then
  cpus_opts="--cpus=$CPUS -e CPUS=$CPUS"
  diag="$diag\n- CPUs:\t$CPUS"
fi

if [ -n "${CPU_SHARES}" ]; then
  cpu_shares_opts="--cpu-shares=$CPU_SHARES -e CPU_SHARES=$CPU_SHARES"
  diag="$diag\n- CPU shares:\t$CPU_SHARES"
fi

echo -e "-----------------------------------"
echo -e "Running run-java test suite:"
echo -e $diag
echo -e "-----------------------------------\n\n"

opts=$(echo "$mem_opts $cpus_opts $cpu_shares_opts $run_opts" | awk '$1=$1')
docker run \
       ${opts} \
       -v ${RUN_JAVA_DIR}:/opt/test \
       -v ${REPORT_DIR}:/opt/reports \
       fabric8/run-java-sh-test:${JDK_TAG}
