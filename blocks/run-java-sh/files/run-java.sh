#!/bin/sh

java_app_dir=${JAVA_APP_DIR}
if [ -z $java_app_dir ]; then
  # Default is current directory
  dir=`dirname "$0"`
  java_app_dir=`cd "${dir}" ; pwd`
fi

# Read in configuration if given
if [ -f "${java_app_dir}/setenv.sh" ]; then
   . ${java_app_dir}/setenv.sh
fi

java_options=${JAVA_OPTIONS}
which agent-bond-opts >/dev/null 2>&1
if [ $? = 0 ]; then
  java_options="${java_options} $(agent-bond-opts)"
fi
if [ "x$JAVA_ENABLE_DEBUG" != "x" ]; then
    debug_port=${JAVA_DEBUG_PORT}:-5005}
    java_options="${java_options} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=${debug_port}"
fi
work_dir=${JAVA_WORKDIR:-${app_dir}}

if [ -z "${JAVA_CLASSPATH}" ]; then
   if [ -f "${java_app_dir}/classpath" ]; then
     classpath=`cat "${java_app_dir}/classpath"`
   else
     classpath="classes:${java_app_dir}/*"
   fi
else
   classpath=${JAVA_CLASSPATH}
fi

# Try hard to find a sane default if no main class and no main class
# is specified explicitely
if [ -z $JAVA_MAIN_CLASS ] && [ -z $JAVA_APP_JAR ]; then
   # Filter out temporary jars from the shade plugin which start with 'original-'
   nr_jars=`ls $java_app_dir/*.jar | grep -v '/original-' | wc -l | tr -d '[[:space:]]'`
   if [ $nr_jars = 1 ]; then
     jar_file=`ls $java_app_dir/*.jar | grep -v '/original-'`
     cp_ext="${java_app_dir}"
   else
     echo "Neither \$JAVA_MAIN_CLASS nor \$JAVA_APP_JAR is set and ${nr_jars} jar files are in ${java_app_dir} (only 1 is expected when using auto-mode)"
     exit 1
   fi
fi

cd ${work_dir}

if [ "x$JAVA_APP_JAR" != "x" ];  then
   if [ -f "$JAVA_APP_JAR" ]; then
       jar_file="$JAVA_APP_JAR"
       cp_ext="${java_app_dir}"
   elif [ -f "${java_app_dir}/$JAVA_APP_JAR" ]; then
       jar_file="${java_app_dir}/$JAVA_APP_JAR"
       cp_ext="${java_app_dir}:${work_dir}"
   else
       echo "No JAR File $JAVA_APP_JAR found"
       exit 1
   fi
fi

if [ "x$jar_file" != "x" ] ; then
   exec java $java_options -cp ${cp_ext} -jar $jar_file $*
else
   exec java $java_options -cp ${classpath}:${java_app_dir}:${work_dir} $JAVA_MAIN_CLASS $*
fi
