
import java.util.Map;
import java.util.List;
import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.io.*;

public class TestMain {
  
  public static void main(String args[]) throws IOException {
    for (String arg : args) {
      System.out.println("ARG::" + arg);
    }
    System.out.println("===================================================");    
    for (Map.Entry<String,String> entry : System.getenv().entrySet()) {
      System.out.println("ENV::" + entry.getKey() + "=" + entry.getValue());
    }
    System.out.println("===================================================");    
    for (String key : System.getProperties().stringPropertyNames()) {
      System.out.println("PROP::" + key + "=" + System.getProperties().get(key));
    }
    System.out.println("===================================================");
    RuntimeMXBean runtimeMxBean = ManagementFactory.getRuntimeMXBean();
    List<String> arguments = runtimeMxBean.getInputArguments();
    for (String arg : arguments) {
      System.out.println("JVM::" + arg);      
    }
    printProcesses();
  }

  private static void printProcesses() throws IOException {
    Process process = new ProcessBuilder("/bin/ps","aux").start();
    BufferedReader br = new BufferedReader(new InputStreamReader(process.getInputStream()));
    System.out.println("===================================================");
    String line;
    while ((line = br.readLine()) != null) {
      System.out.println("PS::" + line);
    }
  }
}
