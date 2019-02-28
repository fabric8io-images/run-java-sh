import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;

public class TestProxy {
  public static void main(String args[]) throws Exception {

    String url = "https://www.google.com";
    if( getStatus(url).contains("Green") ) {
      System.exit(0);
    }

    System.exit(1);
  }

  public static String getStatus(String url) throws IOException {

    String result = "";
    int code = 200;
    try {
      URL siteURL = new URL(url);
      HttpURLConnection connection = (HttpURLConnection) siteURL.openConnection();
      connection.setRequestMethod("GET");
      connection.setConnectTimeout(3000);
      connection.connect();

      code = connection.getResponseCode();
      if (code == 200) {
        result = "-> Green <- " + "Code: " + code;
        ;
      } else {
        result = "-> Yellow <- " + "Code: " + code;
      }
      System.out.println("message = [" + connection.getResponseMessage() + "]");
    } catch (Exception e) {
      result = "-> Red <- " + "Wrong domain - Exception: " + e.getMessage();

    }
    System.out.println(url + "\t\tStatus:" + result);

    return result;
  }

}
