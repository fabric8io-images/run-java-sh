package io.fabric8.runsh;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.CopyOption;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.nio.file.attribute.PosixFilePermission;
import java.util.Collections;
import java.util.HashSet;
import java.util.Scanner;
import java.util.Set;


/**
 * Load and export run-java.sh script
 */
public class RunShLoader
{
    private static final String RUN_SCRIPT = "run-java.sh";
    private static final String LOCATION_RUN_SCRIPT = "/run-java-sh/fp-files/" + RUN_SCRIPT;
    private static final String LOCATION_README = "/run-java-sh/readme.md";

    /**
     * Copy over the run script to a given location
     *
     * If called with --run-java-help print out the README.
     *
     * @param args args given to the script
     */
    public static void main(String[] args) throws IOException, InterruptedException {
        if (args.length > 0) {
            if (args[0].equalsIgnoreCase("help")) {
                printUsage();
                System.exit(0);
            } else if (args[0].equalsIgnoreCase("readme")) {
                System.out.println(getReadme());
                System.exit(0);
            } else if (args[0].equalsIgnoreCase("exec")) {
                Path tempDir = Files.createTempDirectory("run-java");
                File script = copyRunScript(tempDir.toFile());

                ProcessBuilder pb =
                    new ProcessBuilder()
                        .redirectError(ProcessBuilder.Redirect.INHERIT)
                        .redirectInput(ProcessBuilder.Redirect.INHERIT)
                        .redirectOutput(ProcessBuilder.Redirect.INHERIT)
                        .command(getExecArgs(args, "/bin/sh", "-c",
                                             script.getAbsolutePath()));
                if (System.getenv().get("JAVA_APP_DIR") == null) {
                    pb.environment().put("JAVA_APP_DIR", Paths.get("").toAbsolutePath().toString());
                }
                System.exit(pb.start().waitFor());
            } else if (args[0].equalsIgnoreCase("copy")) {
                if (args.length < 2) {
                    System.err.println("No file name to output to given\n");
                    printUsage();
                    System.exit(1);
                }
                File script = copyRunScript(new File(args[1]));
                System.out.println("Created " + script.getAbsolutePath());
            } else {
                System.out.println("Unknown command " + args[0] + "\n");
                printUsage();
                System.exit(1);
            }
        } else {
            System.out.println(getRunScript());
        }
    }

    private static void printUsage() {
        System.out.println(
            "Usage: java -jar run-java.jar <command>\n" +
            "\n" +
            "with the following commands:\n\n" +
            "   help        : This help message\n" +
            "   copy <file> : Write run-java.sh out to this file or directory\n" +
            "   readme      : Print the README\n" +
            "   exec <arg>  : Execute the script directly from the JVM.\n\n" +
            "Note that this will keep the current JVM running, so you end up with 2 JVMs\n" +
            "\n" +
            "By default (no command) print out the content of this script");
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
     * Get the run script it self
     *
     * @return runscript as file
     */
    public static String getRunScript() {
        return loadFromClassPath(LOCATION_RUN_SCRIPT);
    }

    /**
     * Copy the run scripts to a destination in the file system
     *
     * @param destination where to copy run script. Must be a directory.
     * @return return the file to the script
     */
    public static File copyRunScript(File destination) throws IOException {
        Path targetPath;
        if (destination.isDirectory()) {
            targetPath = new File(destination, RUN_SCRIPT).toPath();
        } else {
            if (!destination.getAbsoluteFile().getParentFile().exists()) {
                throw new IOException(String.format("%s is not a directory", destination.getParentFile()));
            }
            targetPath = destination.toPath();
        }
        Files.copy(getInputStream(LOCATION_RUN_SCRIPT), targetPath, StandardCopyOption.REPLACE_EXISTING);
        Set<PosixFilePermission> perms = new HashSet<>(Files.getPosixFilePermissions(targetPath));
        perms.add(PosixFilePermission.OWNER_EXECUTE);
        perms.add(PosixFilePermission.GROUP_EXECUTE);
        perms.add(PosixFilePermission.OTHERS_EXECUTE);
        Files.setPosixFilePermissions(targetPath, perms);
        return targetPath.toFile();
    }

    // ==================================================================================

    private static String loadFromClassPath(String location) {
        Scanner s = new Scanner(getInputStream(location)).useDelimiter("\\A");
        return s.hasNext() ? s.next() : "";
    }

    private static InputStream getInputStream(String location) {
        return RunShLoader.class.getResourceAsStream(location);
    }

    private static String[] getExecArgs(String[] mainArgs, String ... scriptArgs) {
        String[] ret = new String[mainArgs.length - 1 + scriptArgs.length];
        int i=0;
        for (String arg : scriptArgs) {
            ret[i++] = arg;
        }
        for (int j = 1; i < mainArgs.length; j++) {
            ret[i++] = mainArgs[j];
        }
        return ret;
    }
}
