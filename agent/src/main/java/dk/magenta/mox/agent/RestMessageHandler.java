package dk.magenta.mox.agent;

import com.rabbitmq.client.LongString;
import org.json.JSONObject;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;

public class RestMessageHandler implements MessageReceivedCallback {

    private URL url;
    private Map<String, ObjectType> objectTypes;

    public RestMessageHandler(String host, Map<String, ObjectType> objectTypes) throws MalformedURLException {
        this(new URL(host), objectTypes);
    }

    public RestMessageHandler(String protocol, String host, int port, Map<String, ObjectType> objectTypes) throws MalformedURLException {
        this(new URL(protocol, host, port, ""), objectTypes);
    }

    public RestMessageHandler(URL host, Map<String, ObjectType> objectTypes) {
        try {
            this.url = new URL(host.getProtocol(), host.getHost(), host.getPort(), "/");
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }
        this.objectTypes = objectTypes;
    }

    private static String getHeaderString(Map<String, Object> headers, String key) {
        Object value = headers.get(key);
        if (value == null) {
            return null;
        } else {
            return ((LongString) value).toString();
        }
    }

    public void run(Map<String, Object> headers, JSONObject jsonObject) {
        String command = this.getHeaderString(headers, "operation");

        ObjectType objectType = null;
        ObjectType.Operation operation = null;
        for (ObjectType o : this.objectTypes.values()) {
            operation = o.getOperationByCommand(command);
            if (operation != null) {
                objectType = o;
                break;
            }
        }

        if (operation != null && objectType != null) {
            String uuid = this.getHeaderString(headers, "beskedID");
            char[] data = jsonObject.toString().toCharArray();
            if (command != null) {
                try {
                    String path = operation.path;
                    if (path.contains("[uuid]")) {
                        path = path.replace("[uuid]", uuid);
                    }
                    this.rest(operation.method.toString(), path, data);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private URL getURLforPath(String path) throws MalformedURLException {
        return new URL(this.url.getProtocol(), this.url.getHost(), this.url.getPort(), path);
    }

    private void rest(String method, String path, char[] payload) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) this.getURLforPath(path).openConnection();
        System.out.println(method + " " + connection.getURL().toString() + "   " + new String(payload));
        connection.setRequestMethod(method);
        connection.setDoOutput(true);
        connection.setRequestProperty("Content-type", "application/json");
        OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
        out.write(payload);
        out.close();
        InputStream inputStream = connection.getInputStream();
    }
}
