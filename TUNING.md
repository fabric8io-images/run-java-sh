The run script, among other things, tunes the JVM options depending on the host execution environment. The following tests have been carried out to improve the tuning while running a Java application within a Docker container with memory and CPU constraints sets.

# Tests

The following tests exercise a Spring Boot application running within a Docker container.

The source code of this application can be found at [fabric8-quickstarts/spring-boot-camel](https://github.com/fabric8-quickstarts/spring-boot-camel).

The test consists at running the following command multiple times:

```sh
$ ab -n 100000 -c 512 http://localhost/health
```

## Baseline

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 290MB(121MB)/7.64GiB | KO |
1 | 300MB(121MB)/7.64GiB | OK (9.9s start, 1003req/s) |
72 | 575MB(128MB)/46.88GiB | KO |
72 | 600MB(133MB)/46.88GiB | OK (4.1s start, 2641req/s) |

That clearly highlights the scalability issue.

## The `--cpuset-cpus` option

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  --cpuset-cpus=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 290MB(121MB)/7.64GiB | KO |
1 | 300MB(121MB)/7.64GiB | OK (10.1s start, 978req/s) |
72 | 300MB(121MB)/46.88GiB | KO |
72 | 350MB(121MB)/46.88GiB | OK (8.1s start, 1294req/s) |

The `--cpuset-cpus` improves the scaling though the memory requirements are still quite high. So let's optimising...

## Tomcat container tuning

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  --cpuset-cpus=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 210MB(102MB)/7.64GiB | KO |
1 | 220MB(106MB)/7.64GiB | OK (10.3s start, 1064req/s) |
72 | 230MB(112MB)/46.88GiB | KO |
72 | 256MB(121MB)/46.88GiB | (8.2s start, 1655req/s) |

## Run script CPU limits expansion

The script already tries to achieve what the `--cpuset-cpus` Docker option is doing by translating it to JVM options:

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -Djava.util.concurrent.ForkJoinPool.common.parallelism=1 \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 210MB(102MB)/7.64GiB | KO |
1 | 220MB(106MB)/7.64GiB | OK (11.1s start, 1072req/s) |
72 | 450MB(112MB)/46.88GiB | KO |
72 | 512MB(114MB)/46.88GiB | OK (4.5s start, 2099req/s) |

It seems the script fails to capture all the ergonomics that depends on the host number of cores.

Activating Native Memory Tracking (NMT) shows a grow in JIT compiler memory, so let's tune it...

## The `-XX:CICompilerCount` option

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -Djava.util.concurrent.ForkJoinPool.common.parallelism=1 \
  -XX:CICompilerCount=2 \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 220MB(106MB)/7.64GiB | KO |
1 | 230MB(112MB)/7.64GiB | OK (10.2s start, 1077req/s) |
72 | 240MB(107MB)/46.88GiB | KO |
72 | 256MB(112MB)/46.88GiB | OK (3.9s start, 1991req/s) |

## C2 JIT compiler deactivation

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -Djava.util.concurrent.ForkJoinPool.common.parallelism=1 \
  -XX:+TieredCompilation -XX:TieredStopAtLevel=1 \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 160MB(77MB)/7.64GiB | KO |
1 | 170MB(83MB)/7.64GiB | OK (6.2s start, 913req/s) |
72 | 190MB(85MB)/46.88GiB | KO |
72 | 200MB(89MB)/46.88GiB | OK (4.3s start, 1302req/s) |

## Heap size tuning

Activating GC logs shows that the heap requirements are actually quite low, around 40MB:

![GC Activity](src/pics/gc_activity.png "GC Activity")

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -Djava.util.concurrent.ForkJoinPool.common.parallelism=1 \
  -XX:+TieredCompilation -XX:TieredStopAtLevel=1 \
  -Xms<X>m -Xmx<X>m \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 140MB(Xmx40MB)/7.64GiB | OK (6.7s start, 386req/s) |
1 | 150MB(Xmx45MB)/7.64GiB | OK (5.6s start, 849req/s) |
72 | 170MB(Xmx50MB)/46.88GiB | KO |
72 | 180MB(Xmx50MB)/46.88GiB | OK (4.0s start, 1303req/s) |

## The `--cpuset-cpus` option with optimisations

Let's restore the `--cpuset-cpus` option with the JIT compiler and heap size tunings.

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  --cpuset-cpus=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:+TieredCompilation -XX:TieredStopAtLevel=1 \
  -Xms<X>m -Xmx<X>m \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1 | 140MB(Xmx35MB)/7.64GiB | OK (7.6s start, 335req/s) |
1 | 150MB(Xmx45MB)/7.64GiB | OK (5.6s start, 935req/s) |
72 | 140MB(Xmx35MB)/46.88GiB | OK (5.5s start, 433req/s) |
72 | 150MB(Xmx45MB)/46.88GiB | OK (5.1s start, 1330req/s) |
224 | 150MB(Xmx45MB)/46.88GiB | OK (6.3s start, 1141req/s) |

**It manages to achieve 150MB memory limit independently of the host number of cores.**

## Use serial GC

### Command

```sh
$ docker run --rm -it -v `pwd`:/test -p 80:8081 \
  -m=<Y>MB --memory-swap=<Y>MB --memory-swappiness=0 \
  --cpuset-cpus=0 \
  openjdk:8u141 java \
  -XX:+UnlockExperimentalVMOptions -XX:+UseCGroupMemoryLimitForHeap \
  -Dspring.application.json='{"server": {"tomcat":{"max-threads": 1, "min-spare-threads": 1}}}' \
  -XX:+TieredCompilation -XX:TieredStopAtLevel=1 \
  -Xms<X>m -Xmx<X>m \
  -XX:+UseSerialGC \
  -jar /test/target/spring-boot-camel-1.0-SNAPSHOT.jar
```

### Results

| CPU | Memory (Y(Heap)/Total) | Result |
|-----|------------------------|--------|
1| 140MB(Xmx35MB)/7.64GiB | OK (7.6s start, 301req/s) |
1 | 150MB(Xmx45MB)/7.64GiB | OK (5.6s start, 892req/s) |
72 | 140MB(Xmx35MB)/46.88GiB | OK (6.0s start, 436req/s) |
72 | 150MB(Xmx45MB)/46.88GiB | OK (4.6s start, 1409req/s) |
224 | 150MB(Xmx45MB)/46.88GiB | OK (6.3s start, 1140req/s) |

The serial GC does not produce significant improvements.

# Recommandations

* Adjust the JIT compiler thread count with the `-XX:CICompilerCount` option according to the CPU limits,
* Deactivate the C2 JIT compiler with the `-XX:TieredStopAtLevel=1` option when the memory limits are lower than 300MB,
* Adjust the heap size ratio from 50% to 30% when the memory limits are lower than 300MB, maybe with a threshold to preserve a least 110MB of available non-heap memory,
* While setting `-Xms` enables fail-fast behaviour, it may not be wise for cloud native apps, but setting the `-XX:MinHeapFreeRatio=20` and `-XX:MaxHeapFreeRatio=40` options may be beneficial to instruct the heap to shrink aggressively and to grow conservatively.
