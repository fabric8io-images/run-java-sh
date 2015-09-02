The run script can be influenced by the following environment variables:

* **JAVA_APP_DIR** the directory where all JAR files can be
  found. This is `/app` by default.
* **JAVA_WORKDIR** working directory from where to start the JVM. By
  default it is `$JAVA_APP_DIR`
* **JAVA_OPTIONS** options to add when calling `java`
* **JAVA_MAIN_CLASS** A main class to use as argument for `java`. When
  this environment variable is given, all jar files in `$JAVA_APP_DIR`
  are added to the classpath as well as `$JAVA_APP_DIR` and
  `JAVA_WORKDIR` themselves, too.
* **JAVA_APP_JAR** A jar file with an appropriate mainfest so that it
  can be started with `java -jar`. If given it takes precedence of
  `$JAVA_MAIN_CLASS`. In addition `$JAVA_APP_DIR` and `$JAVA_WORKDIR`
  are added to the classpath, too. 
* **JAVA_CLASSPATH** the classpath to use. If not given, the script checks 
  for a file `${JAVA_APP_DIR}/classpath` and use its content literally 
  as classpath. If this file doesn't exists all jars in the app dir are 
  added (`classes:${JAVA_APP_DIR}/*`). 
* **JAVA_ENABLE_DEBUG** If set remote debugging will be switched on
* **JAVA_DEBUG_PORT** Port used for remote debugging. Default: 5005

If neither `$JAVA_APP_JAR` nor `$JAVA_MAIN_CLASS` is given,
`$JAVA_APP_DIR` is checked for a single JAR file which is taken as
`$JAVA_APP_JAR`. If no or more then one jar file is found, the script
throws an error. 

Theses variables (except `${JAVA_APP_DIR}`) can be also set in a
shell config file `${JAVA_APP_DIR}/setenv.sh`, which will be sourced by 
the startup script.

Any arguments given during startup are taken over as arguments to the
Java call. E.g. a `docker run myimage-based-on-java arg1 arg2` will
be hand over the arguments to the Java application.
