**DEMO**

## run-java.sh

`run-java.sh` is a universal startup script for Java
applications. It can be influenced by setting the environment
variables described below.

[run-java.sh](blocks/run-java-sh/files/run-java.sh) can be used
directly or it can be easily included in various build systems:

### Maven Builds

Maven builds can declare a dependency on

```xml
<dependency>
  <groupId>io.fabric8</groupId>
  <artifactId>run-java-sh</artifactId>
  <version>0.0.1-SNAPSHOT</version>
</dependency>
```

Then, within your code the script can be obtained with

```java
// Script as string
String script = RunShLoader.getRunScript();

// Copy it to a destination, possibly somwhere below target/
RunShLoader.copyRunScript(new File("target/assembly/run-java.sh"));
```

You can also use the run script directly from this build:
```
mvn exec:java | sh 
```

### fish-pepper

[fish-pepper](https://github.com/rhuss/fish-pepper) is a Docker build
composition tool based on templates. It has a concept called
**blocks** which is a collection of templates and files to be copied
into a Docker image. Blocks can also be obtained remotely from a Git
repository. In order to use this startup script for fish-pepper, you
need to add the following refernce to the main configuration
`fish-pepper.yml` in you Docker image build:

```yml
blocks:
  - type: "git"
    url: "https://github.com/fabric8io/run-java-sh.git"
    path: "blocks"
```

From within the Docker templates you then can reference this block as
usual e.g. `{{= fp.block('run-java-sh','copy.dck') }}` for adding the
proper `COPY` commands to your Dockerfile **and** copying over the run
script into you Docker build directory.

For more information on fish-pepper please refer to its
[documentation](https://github.com/rhuss/fish-pepper/README.md).

### Environment variables

The most important environment variables are

* **JAVA_MAIN_CLASS** A main class to use as argument for `java`. When
  this environment variable is given, all jar files in `$JAVA_APP_DIR`
  are added to the classpath as well as `$JAVA_APP_DIR` and
  `JAVA_WORKDIR` themselves, too.
* **JAVA_APP_JAR** A jar file with an appropriate mainfest so that it
  can be started with `java -jar`. If given it takes precedence of
  `$JAVA_MAIN_CLASS`. In addition `$JAVA_APP_DIR` and `$JAVA_WORKDIR`
  are added to the classpath, too. 
* **JAVA_OPTIONS** options to add when calling `java`

If the *main class* modus is used, the script tries to lookup a
classpath from the file `classpath`. This could e.g. be created by a
Maven plugin to keep the proper maven dependency order.

If a script `agent-bond-opts` is on your path, it is called to obtain
startup parameters for a
[agent bond](https://github.com/fabric8io/agent-bond), a multipurpose
agent currently including [Jolokia](http://www.jolokia.org) and
[jmx_exporter](https://github.com/prometheus/jmx_exporter), a
Prometheus metrics exporting agent. More information can be found in
the documentation to agent bind, which also provided a fish-pepper
block.

Remote debugging over port 5005 can be switched on by setting the
environment variable `JAVA_ENABLE_DEBUG`. 

These and other supported environment variables are described in
detail in a [separate document](blocks/run-java-sh/readme.md). 
