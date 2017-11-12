package io.fabric8.runsh;

import java.io.*;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.FilenameUtils;
import org.apache.commons.io.IOUtils;

/**
 * Load and export run-java.sh script
 */
public class RunShLoader
{
    public static final String[] LOCATION_RUN_SCRIPTS = new String[] {
            "/run-java-sh/fp-files/container-limits",
            "/run-java-sh/fp-files/debug-options",
            "/run-java-sh/fp-files/java-default-options",
            "/run-java-sh/fp-files/run-java.sh"
    };

    public static final String LOCATION_README = "/run-java-sh/readme.md";


    /**
     * Load and return README from classpath
     *
     * @return readme as string
     */
    public static String getReadme() {
        return loadFromClassPath(LOCATION_README);
    }


    /**
     * Copy the run scripts to a destination in the file system
     *
     * @param destination where to copy run script. Must be a directory.
     */
    public static void copyRunScript(File destination) throws IOException {
        if (!destination.isDirectory()) {
            throw new IOException(String.format("Destination %s is not a directory", destination));
        }
        for (String script : LOCATION_RUN_SCRIPTS) {
            File targetFile = new File(destination, FilenameUtils.getName(script));
            try (FileWriter out = new FileWriter(targetFile)) {
                IOUtils.copy(getInputStream(script), out);
            }
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
