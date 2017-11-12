# Base images for testing
# Build with in the docker dir:
#  docker build --build-arg JDK=9.0.1-11 -t fabric8/run-java-sh-test:openjdk9 .
#  docker build --build-arg JDK=8u151    -t fabric8/run-java-sh-test:openjdk8 .
#
# Run from top-level project dir with
#  docker run -v $(pwd):/test fabric8/run-java-sh-test:openjdk8

ARG JDK=8u151
FROM openjdk:${JDK}

RUN apt-get update \
 && apt-get install -y \
       dash \
       bash \
       ksh \
       ash \
       zsh \
       bats

COPY run_tests.sh /opt
RUN chmod a+x /opt/run_tests.sh

ENTRYPOINT /opt/run_tests.sh
