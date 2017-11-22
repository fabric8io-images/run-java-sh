
# Shell to use for tunning the tests
TEST_SHELL=${TEST_SHELL:-bash}

# Directory holding the source code
RUN_JAVA_DIR=$(cd "$BATS_TEST_DIRNAME/../../fish-pepper/run-java-sh/fp-files" && pwd)

# Run java script
RUN_JAVA="${RUN_JAVA_DIR}/run-java.sh"

# Directory holding the test jars
TEST_JAR_DIR=$(cd "$BATS_TEST_DIRNAME/../test_jars" && pwd)
