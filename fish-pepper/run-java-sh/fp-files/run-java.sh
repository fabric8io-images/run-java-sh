#!/bin/sh
# ===================================================================================
# Generic startup script for running arbitrary Java applications with
# being optimized for running in containers
#
# Usage: ./run-java.sh <args given to Java code>
#
# This script will pick up either a 'fat' jar which can be run with "-jar"
# or you can sepcify a JAVA_MAIN_CLASS.
#
# Source and Documentation can be found
# at https://github.com/fabric8io-images/run-java-sh
#
# Env-variables evaluated in this script:
#
# JAVA_OPTIONS: Checked for already set options
# JAVA_MAX_MEM_RATIO: Ratio use to calculate a default maximum Memory, in percent.
#                     E.g. the "50" value implies that 50% of the Memory
#                     given to the container is used as the maximum heap memory with
#                     '-Xmx'.
#                     It defaults to "25" when the maximum amount of memory available
#                     to the container is below 300M, otherwise defaults to "50".
#                     It is a heuristic and should be better backed up with real
#                     experiments and measurements.
#                     For a good overviews what tuning options are available -->
#                             https://youtu.be/Vt4G-pHXfs4
#                             https://www.youtube.com/watch?v=w1rZOY5gbvk
#                             https://vimeo.com/album/4133413/video/181900266
# Also note that heap is only a small portion of the memory used by a JVM. There are lot
# of other memory areas (metadata, thread, code cache, ...) which addes to the overall
# size. When your container gets killed because of an OOM, then you should tune
# the absolute values.
# JAVA_INIT_MEM_RATIO: Ratio use to calculate a default intial heap memory, in percent.
#                      By default this value is not set.
#
# The following variables are exposed to your Java application:
#
# CONTAINER_MAX_MEMORY: Max memory for the container (if running within a container)
# MAX_CORE_LIMIT: Number of cores available for the container (if running within a container)


# ==========================================================

# Fail on a single failed command in a pipeline (if supported)
(set -o | grep -q pipefail) && set -o pipefail

# Fail on error and undefined vars
set -eu

# ksh is different for defining local vars
if [ -n "${KSH_VERSION:-}" ]; then
  alias local=typeset
fi

# Error is indicated with a prefix in the return value
check_error() {
  local error_msg="$1"
  if echo "${error_msg}" | grep -q "^ERROR:"; then
    echo "${error_msg}"
    exit 1
  fi
}

# The full qualified directory where this script is located in
script_dir() {
  # Default is current directory
  local dir=$(dirname "$0")
  local full_dir=$(cd "${dir}" && pwd)
  echo ${full_dir}
}

# Try hard to find a sane default jar-file
auto_detect_jar_file() {
  local dir="$1"

  # Filter out temporary jars from the shade plugin which start with 'original-'
  local old_dir="$(pwd)"
  cd ${dir}
  if [ $? = 0 ]; then
    local nr_jars="$(ls 2>/dev/null | grep -e '.*\.jar$' | grep -v '^original-' | wc -l | awk '{print $1}')"
    if [ "${nr_jars}" = 1 ]; then
      ls *.jar | grep -v '^original-'
      exit 0
    fi
    cd "${old_dir}"
    echo "ERROR: Neither JAVA_MAIN_CLASS nor JAVA_APP_JAR is set and ${nr_jars} found in ${dir} (1 expected)"
  else
    echo "ERROR: No directory ${dir} found for auto detection"
  fi
}

# Check directories (arg 2...n) for a jar file (arg 1)
find_jar_file() {
  local jar="$1"
  shift;

  # Absolute path check if jar specifies an absolute path
  if [ "${jar}" != ${jar#/} ]; then
    if [ -f "${jar}" ]; then
      echo "${jar}"
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
  local script_dir="$1"

  # Configuration stuff is read from this file
  local run_env_sh="run-env.sh"

  # Load default default config
  if [ -f "${script_dir}/${run_env_sh}" ]; then
    . "${script_dir}/${run_env_sh}"
  fi

  # Check also $JAVA_APP_DIR. Overrides other defaults
  # It's valid to set the app dir in the default script
  JAVA_APP_DIR="${JAVA_APP_DIR:-${script_dir}}"
  if [ -f "${JAVA_APP_DIR}/${run_env_sh}" ]; then
    . "${JAVA_APP_DIR}/${run_env_sh}"
  fi
  export JAVA_APP_DIR

  # Memory and CPU limits are calculated in this script
  local container_limits="container-limits"

  # Read in container limits and export them as environment variables
  if [ -f "${script_dir}/${container_limits}" ]; then
    . "${script_dir}/${container_limits}"
  fi

  # JAVA_LIB_DIR defaults to JAVA_APP_DIR
  export JAVA_LIB_DIR="${JAVA_LIB_DIR:-${JAVA_APP_DIR}}"
  if [ -z "${JAVA_MAIN_CLASS:-}" ] && [ -z "${JAVA_APP_JAR:-}" ]; then
    JAVA_APP_JAR="$(auto_detect_jar_file ${JAVA_APP_DIR})"
    check_error "${JAVA_APP_JAR}"
  fi

  if [ -n "${JAVA_APP_JAR:-}" ]; then
    local jar="$(find_jar_file ${JAVA_APP_JAR} ${JAVA_APP_DIR} ${JAVA_LIB_DIR})"
    check_error "${jar}"
    export JAVA_APP_JAR="${jar}"
  else
    export JAVA_MAIN_CLASS
  fi
}

# Check for standard /opt/run-java-options first, fallback to run-java-options in the path if not existing
run_java_options() {
  if [ -f "/opt/run-java-options" ]; then
    echo "$(. /opt/run-java-options)"
  else
    which run-java-options >/dev/null 2>&1
    if [ $? = 0 ]; then
      echo "$(run-java-options)"
    fi
  fi
}

debug_options() {
  if [ -n "${JAVA_ENABLE_DEBUG:-}" ] || [ -n "${JAVA_DEBUG_ENABLE:-}" ] ||  [ -n "${JAVA_DEBUG:-}" ]; then
    local debug_port="${JAVA_DEBUG_PORT:-5005}"
    local suspend_mode="n"
    if [ -n "${JAVA_DEBUG_SUSPEND:-}" ]; then
      if ! echo "${JAVA_DEBUG_SUSPEND}" | grep -q -e '^\(false\|n\|no\|0\)$'; then
        suspend_mode="y"
      fi
    fi
    echo "-agentlib:jdwp=transport=dt_socket,server=y,suspend=${suspend_mode},address=${debug_port}"
  fi
}

# Read in a classpath either from a file with a single line, colon separated
# or given line-by-line in separate lines
# Arg 1: path to claspath (must exist), optional arg2: application jar, which is stripped from the classpath in
# multi line arrangements
format_classpath() {
  local cp_file="$1"
  local app_jar="$2"

  local wc_out=$(wc -l $1 2>&1)
  if [ $? -ne 0 ]; then
    echo "Cannot read lines in ${cp_file}: $wc_out"
    exit 1
  fi

  local nr_lines=$(echo $wc_out | awk '{ print $1 }')
  if [ ${nr_lines} -gt 1 ]; then
    local sep=""
    local classpath=""
    while read file; do
      local full_path="${JAVA_LIB_DIR}/${file}"
      # Don't include app jar if include in list
      if [ "${app_jar}" != "${full_path}" ]; then
        classpath="${classpath}${sep}${full_path}"
      fi
      sep=":"
    done < "${cp_file}"
    echo "${classpath}"
  else
    # Supposed to be a single line, colon separated classpath file
    cat "${cp_file}"
  fi
}

# ==============================================================================

# parse the URL
parse_url() {
  #[scheme://][user[:password]@]host[:port][/path][?params]
  echo "$1" | sed -e "s+^\(\([^:]*\)://\)\?\(\([^:@]*\)\(:\([^@]*\)\)\?@\)\?\([^:/?]*\)\(:\([^/?]*\)\)\?.*$+ local scheme='\2' username='\4' password='\6' hostname='\7' port='\9'+"
}

java_proxy_options() {
  local url="$1"
  local transport="$2"
  local ret=""

  if [ -n "$url" ] ; then
    eval $(parse_url "$url")
    if [ -n "$hostname" ] ; then
      ret="-D${transport}.proxyHost=${hostname}"
    fi
    if [ -n "$port" ] ; then
      ret="$ret -D${transport}.proxyPort=${port}"
    fi
    if [ -n "$username" -o -n "$password" ] ; then
      echo "WARNING: Proxy URL for ${transport} contains authentication credentials, these are not supported by java" >&2
    fi
  fi
  echo "$ret"
}

# Check for proxy options and echo if enabled.
proxy_options() {
  local ret=""
  ret="$(java_proxy_options "${https_proxy:-${HTTPS_PROXY:-}}" https)"
  ret="$ret $(java_proxy_options "${http_proxy:-${HTTP_PROXY:-}}" http)"

  local noProxy="${no_proxy:-${NO_PROXY:-}}"
  if [ -n "$noProxy" ] ; then
    ret="$ret -Dhttp.nonProxyHosts=\"$(echo $noProxy | sed -e 's/,[[:space:]]*/|/g')\""
  fi
  echo "$ret"
}

# ==============================================================================

# Set process name if possible
exec_args() {
  EXEC_ARGS=""
  if [ -n "${JAVA_APP_NAME:-}" ]; then
    # Not all shells support the 'exec -a newname' syntax..
    if $(exec -a test true 2>/dev/null); then
      echo "-a '${JAVA_APP_NAME}'"
    fi
  fi
}

# Combine all java options
java_options() {
  local script_dir=$(script_dir)
  local java_default_options=""

  if [ -f "${script_dir}/java-default-options" ]; then
    java_default_options=$(${script_dir}/java-default-options)
  fi

  # Normalize spaces with awk (i.e. trim and elimate double spaces)
  # See e.g. https://www.physicsforums.com/threads/awk-1-1-1-file-txt.658865/ for an explanation
  # of this awk idiom
  echo "${JAVA_OPTIONS:-} $(run_java_options) $(debug_options) $(proxy_options) ${java_default_options}" | awk '$1=$1'
}

# Fetch classpath from env or from a local "run-classpath" file
classpath() {
  local cp_path="."
  if [ "${JAVA_LIB_DIR}" != "${JAVA_APP_DIR}" ]; then
    cp_path="${cp_path}:${JAVA_LIB_DIR}"
  fi
  if [ -z "${JAVA_CLASSPATH:-}" ] && [ -n "${JAVA_MAIN_CLASS:-}" ]; then
    if [ -n "${JAVA_APP_JAR:-}" ]; then
      cp_path="${cp_path}:${JAVA_APP_JAR}"
    fi
    if [ -f "${JAVA_LIB_DIR}/classpath" ]; then
      # Classpath is pre-created and stored in a 'run-classpath' file
      cp_path="${cp_path}:$(format_classpath ${JAVA_LIB_DIR}/classpath ${JAVA_APP_JAR})"
    else
      # No order implied
      cp_path="${cp_path}:${JAVA_APP_DIR}/*"
    fi
  elif [ -n "${JAVA_CLASSPATH:-}" ]; then
    # Given from the outside
    cp_path="${JAVA_CLASSPATH}"
  fi
  echo "${cp_path}"
}

# ==============================================================================

# Start JVM
startup() {
  # Initialize environment
  load_env $(script_dir)

  local args
  cd ${JAVA_APP_DIR}
  if [ -n "${JAVA_MAIN_CLASS:-}" ] ; then
     args="${JAVA_MAIN_CLASS}"
  else
     # Either JAVA_MAIN_CLASS or JAVA_APP_JAR has been set in load_env()
     # So no ${JAVA_APP_JAR:-} safeguard is needed here. Actually its good when the script
     # dies here if JAVA_APP_JAR would not be set for some reason (see option `set -u` above)
     args="-jar ${JAVA_APP_JAR}"
  fi
  # Don't put ${args} in quotes, otherwise it would be interpreted as a single arg.
  # However it could be two args (see above). zsh doesn't like this btw, but zsh is not
  # supported anyway.
  echo exec $(exec_args) java $(java_options) -cp "$(classpath)" ${args} $*
  exec $(exec_args) java $(java_options) -cp "$(classpath)" ${args} $*
}

# =============================================================================
# Fire up
startup $*
