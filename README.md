## run-java.sh

[![CircleCI](https://circleci.com/gh/fabric8io-images/run-java-sh.svg?style=svg)](https://circleci.com/gh/fabric8io-images/run-java-sh) | [Usage](fish-pepper/run-java-sh/readme.md)

`run-java.sh` is a universal startup script for Java applications, especially crafted for being run from within containers.

Some highlights:

* Chooses sane default for JVM parameters based on container constraints on memory and cpus. See this [research investigation](TUNING.md) by [@astefanutti](https://github.com/astefanutti) which explains the rational behind the parameters chosen.
* Supports
  - bash
  - sh (plain bourne shell)
  - ash
  - dash
  - ksh
  `zsh` is *not supported* yet.
* Support for switching on debugging via the environment variable `JAVA_DEBUG`
* Autodetection of JAR files within a directory
* Support for [fish-pepper](https://github.com/fabric8io-images/fish-pepper) so that this script can be used as a fish-pepper block
* Integration tests for all those shells mentioned above. See the build on [CircleCI](https://circleci.com/gh/fabric8io-images/run-java-sh) for more details. Look in the "Artifacts" tab of a test run for the test results.
* Maven artefacts for easy usage of this script in Maven projects.
 
The full documentation for `run-java.sh` can be found in this [README](fish-pepper/run-java-sh/readme.md)

### Installation

[run-java.sh](fish-pepper/run-java-sh/fp-files/run-java.sh) can be used directly by copying all files from [fish-pepper/run-java-sh/fp-files](fish-pepper/run-java-sh/fp-files) to a directory in your container or it can be easily included in various build systems.

#### Maven Builds

Maven builds can declare a dependency on

```xml
<dependency>
  <groupId>io.fabric8</groupId>
  <artifactId>run-java-sh</artifactId>
  <version>0.1-SNAPSHOT</version>
</dependency>
```

Then, within your code the script can be obtained with

```java

// Copy it to a destination, possibly somwhere below target/
RunShLoader.copyRunScript(new File("target/assembly/startup/"));
```

#### fish-pepper

[fish-pepper](https://github.com/fabric8io-images/fish-pepper) is a Docker build composition tool based on templates. It has a concept called **blocks** which is a collection of templates and files to be copied into a Docker image. Blocks can also be obtained remotely from a Git repository. In order to use this startup script for fish-pepper, you need to add the following refernce to the main configuration `fish-pepper.yml` in you Docker image build:

```yml
blocks:
  - type: "git"
    url: "https://github.com/fabric8io/run-java-sh.git"
    path: "fish-pepper"
```

From within the Docker templates you then can reference this block as usual e.g. `{{= fp.block('run-java-sh','copy.dck') }}` for adding the proper `COPY` commands to your Dockerfile **and** copying over the run script into you Docker build directory.

For more information on fish-pepper please refer to its [documentation](https://github.com/fabric8io-images/fish-pepper/README.md).


### Integration Test

`run-java.sh` uses [bats](https://github.com/sstephenson/bats) for bash integraton testing. 
The tests are typically fired up by using a Docker test container which contains all shells which are supported, but you can call the test locally, too.

#### Running test locally

* Install `bats` (e.g. via `brew install bats` on macOS)
* Goto directory `test/t`
* Run: `bats .`
* In order to use a different shell, set the environment variabel `$TEST_SHELL` : `TEST_SHELL=ash bats .`. This shell must be installed locally, too, of course.
* You can run individual tests by calling a teat file directly: `bats 01_basic.bats`

#### Running in a Docker container

* Be sure to have a local Docker daemon running and accessible
* Then just call `test/run_all.sh`
* The following environment variables can influence this script:
  - `JDK_TAG` : Which JVM to use for testing. Should be `openjdk8` or `openjdk9`
  - `MEMORY` : A memory limit to set to the container
  - `CPUS` : Number of cores to constraint the container to
  - `REPORT_DIR` : Directory where to store the reports. By default this in the top-level `reports/` directory. 

Example:

```
JDK_TAG=openjdk9 MEMORY=400m CPUS=1.5 test/run_all.sh
```

The builder containers can be recreated from the Dockerfile in `test/docker`. Look into the [CircleCI build](.circleci/config.yml) for how these containers are built.

#### CircleCI

The integrations tests run on [CircleCI](https://circleci.com/) on every commit and PR. The configuration can be found in [config.yml](.circleci/config.yml). You find the test reporst in the "Artifacts" tap of a build, e.g. like [here](https://circleci.com/gh/fabric8io-images/run-java-sh/127#artifacts/containers/0).

Currently the following combinations are tested

* OpenJDK 8 and OpenJDK 9
* Memory limits: unlimited, 160m, 400m
* CPUs: unlimited, 1.5
