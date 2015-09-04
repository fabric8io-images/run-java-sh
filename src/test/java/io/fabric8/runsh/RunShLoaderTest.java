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

import org.apache.commons.io.FileUtils;
import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.assertEquals;

/**
 * @author roland
 * @since 04/09/15
 */
public class RunShLoaderTest {

    private String rootDir;

    @Before
    public void setup() {
        rootDir = System.getProperty("root.dir");
        rootDir = rootDir == null ? "" : rootDir + "/";
    }

    @Test
    public void checkRunScript() throws IOException {
        checkLoad(RunShLoader.getRunScript(), "blocks/run-java-sh/files/run-java.sh");
        checkLoad(RunShLoader.getReadme(), "blocks/run-java-sh/readme.md");
    }

    @Test
    public void checkCopyScript() throws IOException {
        File dest = File.createTempFile("run",".sh");
        RunShLoader.copyRunScript(dest);
        String orig = RunShLoader.getRunScript();
        String copied = FileUtils.readFileToString(dest);
        assertEquals(orig,copied);
    }

    // ======================================================================================================

    private void checkLoad(String toCheck,String location) throws IOException {
        String loadedFromFileSystem = load(location);
        assertEquals(loadedFromFileSystem,toCheck);
    }

    private String load(String location) throws IOException {
        return FileUtils.readFileToString(new File(rootDir + location));
    }

}
