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
import java.util.Scanner;

import org.junit.Test;

import static org.junit.Assert.assertEquals;

/**
 * @author roland
 * @since 04/09/15
 */
public class RunShLoaderTest {

    @Test
    public void checkCopyScript() throws IOException {
        Path dest =  Files.createTempDirectory("run");
        RunShLoader.copyRunScript(dest.toFile());

        String files[] = dest.toFile().list();
        assertEquals(1, files.length);
        String extracted = new String(Files.readAllBytes(new File(dest.toFile(), "run-java.sh").toPath()));
        String stored = RunShLoader.loadFromClassPath("/run-java-sh/fp-files/run-java.sh");
        assertEquals(stored, extracted);
    }
}
