#!/bin/sh

# ==========================================================
# Generic run script for running arbitrary Java applications
#
# Source and Documentation can be found
# at https://github.com/fabric8io/run-java-sh
#
# ==========================================================


# Error is indicated with a prefix in the return value
check_error() {
  local msg=$1
  if echo ${msg} | grep -q "^ERROR:"; then
    echo ${msg}
    exit 1
  fi
}

# The full qualified directory where this script is located
get_script_dir() {
  # Default is current directory
  local dir=`dirname "$0"`
  local full_dir=`cd "${dir}" ; pwd`
  echo ${full_dir}
}

# Try hard to find a sane default jar-file
auto_detect_jar_file() {
  local dir=$1

  # Filter out temporary jars from the shade plugin which start with 'original-'
  local old_dir=$(pwd)
  cd ${dir}
  if [ $? = 0 ]; then
    local nr_jars=`ls *.jar 2>/dev/null | grep -v '^original-' | wc -l | tr -d '[[:space:]]'`
    if [ ${nr_jars} = 1 ]; then
      ls *.jar | grep -v '^original-'
      exit 0
    fi
    cd ${old_dir}
    echo "ERROR: Neither \$JAVA_MAIN_CLASS nor \$JAVA_APP_JAR is set and ${nr_jars} found in ${dir} (1 expected)"
  else
    echo "ERROR: No directory ${dir} found for autodetection"
  fi
}

# Check directories for a jar file
get_jar_file() {
  local jar=$1
  shift;

  if [ "${jar:0:1}" = "/" ]; then
    if [ -f ${jar} ]; then
      echo ${jar}
    else
      echo "ERROR: No such file ${jar}"
    fi
  else
    for dir in $*; do
      if [ -f "${dir}/$jar" ]; then
        echo "${dir}/$jar"
        return
      fi
    done
    echo "ERROR: No ${jar} found in $*"
  fi
}

load_env() {
  local script_dir=$1

  # Configuration stuff is read from this file
  local run_env_sh="run-env.sh"

  # Load default default config
  if [ -f "${script_dir}/${run_env_sh}" ]; then
    source "${script_dir}/${run_env_sh}"
  fi

  # Check also $JAVA_APP_DIR. Overrides other defaults
  # It's valid to set the app dir in the default script
  if [ -z ${JAVA_APP_DIR} ]; then
    JAVA_APP_DIR=${script_dir}
  else
    if [ -f "${JAVA_APP_DIR}/${run_env_sh}" ]; then
      source "${JAVA_APP_DIR}/${run_env_sh}"
    fi
  fi
  export JAVA_APP_DIR

  # Workdir default to JAVA_APP_DIR
  export JAVA_WORK_DIR=${JAVA_WORK_DIR:-${JAVA_APP_DIR}}
  if [ -z ${JAVA_MAIN_CLASS} ] && [ -z ${JAVA_APP_JAR} ]; then
    JAVA_APP_JAR="$(auto_detect_jar_file ${JAVA_APP_DIR})"
    check_error "${JAVA_APP_JAR}"
  fi
  if [ "x${JAVA_APP_JAR}" != x ]; then
    local jar="$(get_jar_file ${JAVA_APP_JAR} ${JAVA_APP_DIR} ${JAVA_WORK_DIR})"
    check_error "${jar}"
    export JAVA_APP_JAR=${jar}
  else
    export JAVA_MAIN_CLASS
  fi
}

# Check for agent-bond-opts first, fallback to jolokia-opts if not existing
java_options_from_cmd() {
  which run-java-options >/dev/null 2>&1
  if [ $? = 0 ]; then
    echo `run-java-options`
  fi
}

# Echo the proper options to switch on debugging
debug_options() {
  if [ "x${JAVA_ENABLE_DEBUG}" != "x" ]; then
    local debug_port=${JAVA_DEBUG_PORT:-5005}
    echo "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${debug_port}"
  fi
}

# Combine all java options
get_java_options() {
  # Normalize spaces (i.e. trim and elimate double spaces)
  echo "${JAVA_OPTIONS} $(debug_options) $(java_options_from_cmd)"
}

# Fetch classpath from env or from a local "run-classpath" file
get_classpath() {
  local cp_path="."
  if [ "x${JAVA_WORK_DIR}" != "x${JAVA_APP_DIR}" ]; then
    cp_path="${cp_path}:${JAVA_APP_DIR}"
  fi
  if [ -z "${JAVA_CLASSPATH}" ] && [ "x${JAVA_MAIN_CLASS}" != x ]; then
    if [ "x${JAVA_APP_JAR}" != x ]; then
      cp_path="${cp_path}:${JAVA_APP_JAR}"
    fi
    if [ -f "${JAVA_APP_DIR}/classpath" ]; then
      # Classpath is pre-created and stored in a 'run-classpath' file
      cp_path="${cp_path}:`cat ${JAVA_APP_DIR}/classpath`"
    else
      # No order implied
      cp_path="${cp_path}:${JAVA_APP_DIR}/*"
    fi
  elif [ "x${JAVA_CLASSPATH}" != x ]; then
    # Given from the outside
    cp_path=${JAVA_CLASSPATH}
  fi
  echo ${cp_path}
}

# Set process name if possible
get_exec_args() {
  EXEC_ARGS=""
  if [ "x${JAVA_APP_NAME}" != x ]; then
    # Not all shells support the 'exec -a newname' syntax..
    `exec -a test true 2>/dev/null`
    if [ "$?" = 0 ] ; then
      echo "-a '${JAVA_APP_NAME}'"
    else
      # Lets switch to bash if you have it installed...
      if [ -f "/bin/bash" ] ; then
        exec "/bin/bash" $0 $@
      fi
    fi
  fi
}

# Start JVM
startup() {
  # Initialize environment
  load_env $(get_script_dir)

  local args
  cd ${JAVA_WORK_DIR}
  if [ "x$JAVA_MAIN_CLASS" != x ] ; then
     args="${JAVA_MAIN_CLASS}"
  else
     args="-jar ${JAVA_APP_JAR}"
  fi
  exec $(get_exec_args) java $(get_java_options) -cp "$(get_classpath)" ${args} $*
}

# =============================================================================
# Fire up
startup $*
