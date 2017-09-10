The run script can be influenced by the following environment variables:

* **JAVA_APP_DIR** the directory where the application resides. All paths in your application are relative to this directory.
* **JAVA_LIB_DIR** directory holding the Java jar files as well an optional `classpath` file which holds the classpath. Either as a single line classpath (colon separated) or with jar files listed line-by-line. If not set **JAVA_LIB_DIR** is the same as **JAVA_APP_DIR**.
* **JAVA_OPTIONS** options to add when calling `java`
* **JAVA_MAX_MEM_RATIO** is used when no `-Xmx` option is given in `JAVA_OPTIONS`. This is used to calculate a default maximal Heap Memory based on a containers restriction. If used in a Docker container without any memory constraints for the container then this option has no effect. If there is a memory constraint then `-Xmx` is set to a ratio of the container available memory as set here. The default is 50 which means 50% of the available memory is used as an upper boundary. You can skip this mechanism by setting this value to 0 in which case no `-Xmx` option is added.
* **JAVA_MAX_CORE** restrict manually the number of cores available which is used for calculating certain defaults like the number of garbage collector threads. If set to 0 no base JVM tuning based on the number of cores is performed.
* **JAVA_DIAGNOSTICS** set this to get some diagnostics information to standard out when things are happening
* **JAVA_MAIN_CLASS** A main class to use as argument for `java`. When this environment variable is given, all jar files in `$JAVA_APP_DIR` are added to the classpath as well as `$JAVA_LIB_DIR`.
* **JAVA_APP_JAR** A jar file with an appropriate manifest so that it can be started with `java -jar` if no `$JAVA_MAIN_CLASS` is set. In all cases this jar file is added to the classpath, too.
* **JAVA_APP_NAME** Name to use for the process
* **JAVA_CLASSPATH** the classpath to use. If not given, the startup script checks for a file `${JAVA_APP_DIR}/classpath` and use its content literally as classpath. If this file doesn't exists all jars in the app dir are added (`classes:${JAVA_APP_DIR}/*`).
* **JAVA_DEBUG** If set remote debugging will be switched on
* **JAVA_DEBUG_SUSPEND** If set enables suspend mode in remote debugging
* **JAVA_DEBUG_PORT** Port used for remote debugging. Default: 5005

If neither `$JAVA_APP_JAR` nor `$JAVA_MAIN_CLASS` is given, `$JAVA_APP_DIR` is checked for a single JAR file which is taken as `$JAVA_APP_JAR`. If no or more then one jar file is found, an error is thrown.

The classpath is build up with the following parts:

* If `$JAVA_CLASSPATH` is set, this classpath is taken.
* The current directory (".") is added first.
* If the current directory is not the same as `$JAVA_APP_DIR`, `$JAVA_APP_DIR` is added.
* If `$JAVA_MAIN_CLASS` is set, then
  - A `$JAVA_APP_JAR` is added if set
  - If a file `$JAVA_APP_DIR/classpath` exists, its content is appended to the classpath. This file
    can be either a single line with the jar files colon separated or a multi-line file where each line
    holds the path of the jar file relative to `$JAVA_LIB_DIR` (which by default is the `$JAVA_APP_DIR`)
  - If this file is not set, a `${JAVA_APP_DIR}/*` is added which effectively adds all
    jars in this directory in alphabetical order.

These variables can be also set in a shell config file `run-env.sh`, which will be sourced by the startup script. This file can be located in the directory where the startup script is located and in `${JAVA_APP_DIR}`, whereas environment variables in the latter override the ones in `run-env.sh` from the script directory.

This startup script also checks for a command `run-java-options`. If existent it will be called and the output is added to the environment variable `$JAVA_OPTIONS`.

The startup script also exposes some environment variables describing container limits which can be used by applications:

* **CONTAINER_CORE_LIMIT** a calculated core limit as described in https://www.kernel.org/doc/Documentation/scheduler/sched-bwc.txt
* **CONTAINER_MAX_MEMORY** memory limit given to the container

Any arguments given during startup are taken over as arguments to the Java app.
