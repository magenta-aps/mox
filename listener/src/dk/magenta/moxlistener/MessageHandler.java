package dk.magenta.moxlistener;

import com.rabbitmq.client.LongString;
import org.json.JSONObject;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.Map;
import java.util.UUID;

/**
 * Created by lars on 30-07-15.
 */
public class MessageHandler implements MessageReceivedCallback {

    private URL url;

    public MessageHandler(String host) throws MalformedURLException {
        this(new URL(host));
    }

    public MessageHandler(String protocol, String host, int port) throws MalformedURLException {
        this(new URL(protocol, host, port, ""));
    }

    public MessageHandler(URL host) {
        try {
            this.url = new URL(host.getProtocol(), host.getHost(), host.getPort(), "/");
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }
    }

    private static String getHeaderString(Map<String, Object> headers, String key) {
        return ((LongString) headers.get(key)).toString();
    }

    @Override
    public void run(Map<String, Object> headers, JSONObject jsonObject) {
        String operation = this.getHeaderString(headers, "operation");
        String uuid = this.getHeaderString(headers, "beskedID");
        if (uuid == null) {
            uuid = UUID.randomUUID().toString();
        }
        char[] data = jsonObject.toString().toCharArray();
        if (operation != null) {
            try {
                switch (operation) {
                    case "opretFacet":
                    case "opdaterFacet":
                    case "passiverFacet":
                        this.put("/klassifikation/facet/" + uuid, data);
                        break;
                    case "sletFacet":
                        this.delete("/klassifikation/facet/" + uuid, data);
                        break;
                    case "opretKlasse":
                    case "opdaterKlasse":
                        this.put("/klassifikation/klasse/" + uuid, data);
                        break;
                    case "opretItSystem":
                    case "opdaterItSystem":
                        this.put("/organisation/itsystem/" + uuid, data);
                        break;
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    private URL getURLforPath(String path) throws MalformedURLException {
        return new URL(this.url.getProtocol(), this.url.getHost(), this.url.getPort(), path);
    }

    private void put(String path, char[] payload) throws IOException {
        this.rest("PUT", path, payload);
    }

    private void delete(String path, char[] payload) throws IOException {
        this.rest("DELETE", path, payload);
    }

    private void rest(String method, String path, char[] payload) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) this.getURLforPath(path).openConnection();
        System.out.println(method + " "+connection.getURL().toString()+"   "+new String(payload));
        connection.setRequestMethod(method);
        connection.setDoOutput(true);
        connection.setRequestProperty("Content-type", "application/json");
        OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
        out.write(payload);
        out.close();
        connection.getInputStream();
    }
}
