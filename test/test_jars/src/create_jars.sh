#!/bin/sh

mkdir tmp
cp TestMain.java tmp

cd tmp
javac TestMain.java
cat - <<EOT >manifest.txt
Main-Class: TestMain
EOT

jar cfm ../../test.jar manifest.txt *.class
jar cf ../../test-without-manifest-entry.jar *.class

cd ..
rm -rf tmp
