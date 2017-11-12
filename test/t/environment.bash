
# Shell to use for tunning the tests
TEST_SHELL=${TEST_SHELL:-bash}

# Directory holding the source code
RUN_JAVA_DIR=$(cd "$BATS_TEST_DIRNAME/../../fish-pepper/run-java-sh/fp-files" && pwd)

# Run java script
RUN_JAVA="${RUN_JAVA_DIR}/run-java.sh"

# Helper scripts
DEBUG_OPTIONS="${RUN_JAVA_DIR}/debug-options"
CONTAINER_LIMITS="${RUN_JAVA_DIR}/container-limits"
JAVA_DEFAULT_OPTIONS="${RUN_JAVA_DIR}/java-default-options"

# Directory holding the test jars
TEST_JAR_DIR=$(cd "$BATS_TEST_DIRNAME/../test_jars" && pwd)
