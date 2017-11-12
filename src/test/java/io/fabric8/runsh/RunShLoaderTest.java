package io.fabric8.runsh;/*
 *
 * Copyright 2014 Roland Huss
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

import org.apache.commons.io.FileUtils;
import org.apache.commons.io.IOUtils;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

/**
 * @author roland
 * @since 04/09/15
 */
public class RunShLoaderTest {

    @Test
    public void checkCopyScript() throws IOException {
        Path dest =  Files.createTempDirectory("run");
        RunShLoader.copyRunScript(dest.toFile());

        Set<String> filesToCheck =
            new HashSet<>(
                Arrays.asList("run-java.sh", "container-limits",
                              "debug-options", "java-default-options"));

        for (String script : dest.toFile().list()) {
            assertTrue(filesToCheck.remove(script));
            String extracted = FileUtils.readFileToString(new File(dest.toFile(), script));
            String stored = loadFromClassPath("/run-java-sh/fp-files/" + script);
            assertEquals(stored, extracted);
        }
        assertEquals(0, filesToCheck.size());
    }

    // ======================================================================================================


    private String loadFromClassPath(String location) {
        try {
            return IOUtils.toString(getClass().getResourceAsStream(location));
        } catch (IOException e) {
            throw new IllegalStateException("Internal: Cannot load " + location + ":" + e,e);
        }
    }

}
