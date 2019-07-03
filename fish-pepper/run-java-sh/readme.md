### run-java.sh

This general purpose startup script is optimized for running Java application from within containers. It is for Version >= 8u212 only. It is called like

```
./run-java.sh <sub-command> <options>
```
`run-java.sh` knows two sub-commands:

* `options` to print out JVM option which can be used for own invocation of Java apps (like Maven or Tomcat). It respects container constraints and includes all magic which is used by this script
* `run` executes a Java application as described below. This is also the default command so you can skip adding this command.

### Running a Java application

When no subcommand is given (or when you provide the default subcommand `run`), then by default this scripts starts up Java application.

The startup process is configured mostly via environment variables:

* **JAVA_APP_DIR** the directory where the application resides. All paths in your application are relative to this directory. By default it is the same directory where this startup script resides.
* **JAVA_LIB_DIR** directory holding the Java jar files as well an optional `classpath` file which holds the classpath. Either as a single line classpath (colon separated) or with jar files listed line-by-line. If not set **JAVA_LIB_DIR** is the same as **JAVA_APP_DIR**.
* **JAVA_OPTIONS** options to add when calling `java`
* **JAVA_DIAGNOSTICS** set this to get some diagnostics information to standard out when things are happening
* **JAVA_MAIN_CLASS** A main class to use as argument for `java`. When this environment variable is given, all jar files in `$JAVA_APP_DIR` are added to the classpath as well as `$JAVA_LIB_DIR`.
* **JAVA_APP_JAR** A jar file with an appropriate manifest so that it can be started with `java -jar` if no `$JAVA_MAIN_CLASS` is set. In all cases this jar file is added to the classpath, too.
* **JAVA_APP_NAME** Name to use for the process
* **JAVA_CLASSPATH** the classpath to use. If not given, the startup script checks for a file `${JAVA_APP_DIR}/classpath` and use its content literally as classpath. If this file doesn't exists all jars in the app dir are added (`classes:${JAVA_APP_DIR}/*`).
* **JAVA_DEBUG** If set remote debugging will be switched on
* **JAVA_DEBUG_SUSPEND** If set enables suspend mode in remote debugging
* **JAVA_DEBUG_PORT** Port used for remote debugging. Default: 5005
* **HTTP_PROXY** The URL of the proxy server that translates into the `http.proxyHost` and `http.proxyPort` system properties.
* **HTTPS_PROXY** The URL of the proxy server that translates into the `https.proxyHost` and `https.proxyPort` system properties.
* **no_proxy**, **NO_PROXY** The list of hosts that should be reached directly, bypassing the proxy, that translates into the `http.nonProxyHosts` system property.

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

Any arguments given to the script are given through directly as argument to the Java application.

Example:

```
# Set the application directory directly
export JAVA_APP_DIR=/deployments
# Start the jar in JAVA_APP_DIR with the given arguments
./run-java.sh --user maxmorlock --password secret
```


### Options

The subcommand `options` can be used to print options to standard output so that is can be easily used to feed it to another, Java based application.

When no extra arguments are given, all defaults will be used, which can be influenced with the environment variables described above.

You can select specific sets of options by providing additional arguments:

* `--debug` : Java debug options if `JAVA_DEBUG` is set
* `--proxy` : Evaluate proxy environments variables
* `--diagnostics` : Print diagnostics options when `JAVA_DIAGNOSTICS` is set
* `--java-default` : Default options

Example:

```
# Call Maven with the proper proxy settings when running in an container
export MAVEN_OPTS="$(run-java.sh options --proxy)"
mvn clean install
```
