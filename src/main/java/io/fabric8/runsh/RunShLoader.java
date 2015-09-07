package io.fabric8.runsh;

import java.io.*;

import org.apache.commons.io.IOUtils;

/**
 * Load and export run-java.sh script
 */
public class RunShLoader
{
    // Print out run script when called
    public static void main( String[] args ) {
        System.out.println(getRunScript());
    }

    public static final String LOCATION_RUN_SCRIPT = "/run-java-sh/fp-files/run-java.sh";
    public static final String LOCATION_README = "/run-java-sh/readme.md";

    /**
     * Get the run script as a string
     *
     * @return run script as string
     */
    public static String getRunScript() {
        return loadFromClassPath(LOCATION_RUN_SCRIPT);
    }

    /**
     * Load and return README from classpath
     *
     * @return readme as string
     */
    public static String getReadme() {
        return loadFromClassPath(LOCATION_README);
    }

    /**
     * Copy the run script to a destination in the file system
     *
     * @param destination where to copy run script
     */
    public static void copyRunScript(File destination) throws IOException {
        FileWriter out = new FileWriter(destination);
        try {
            IOUtils.copy(getInputStream(LOCATION_RUN_SCRIPT), out);
        } finally {
            out.close();
        }
    }

    // ==================================================================================

    private static String loadFromClassPath(String location) {
        try {
            return IOUtils.toString(getInputStream(location));
        } catch (IOException e) {
            throw new IllegalStateException("Internal: Cannot load " + location + ":" + e,e);
        }
    }

    private static InputStream getInputStream(String location) {
        return RunShLoader.class.getResourceAsStream(location);
    }


}
