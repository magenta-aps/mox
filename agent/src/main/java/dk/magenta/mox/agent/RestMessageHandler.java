package dk.magenta.mox.agent;

import com.rabbitmq.client.LongString;
import org.apache.commons.io.IOUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.OutputStreamWriter;
import java.net.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.StringJoiner;
import java.util.concurrent.*;

public class RestMessageHandler implements MessageHandler {

    private URL url;
    private Map<String, ObjectType> objectTypes;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);

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

    public Future<String> run(Map<String, Object> headers, JSONObject jsonObject) {
        String objectTypeName = this.getHeaderString(headers, MessageInterface.HEADER_OBJECTTYPE);
        String operationName = this.getHeaderString(headers, MessageInterface.HEADER_OPERATION);


        ObjectType objectType = this.objectTypes.get(objectTypeName);
        if (objectType != null) {
            ObjectType.Operation operation = objectType.getOperation(operationName);

            String query = this.getHeaderString(headers, MessageInterface.HEADER_QUERY);
            HashMap<String, ArrayList<String>> queryMap = null;
            System.out.println("query: "+query);

            if (query != null) {
                JSONObject queryObject = new JSONObject(query);
                queryMap = new HashMap<>();
                for (String key : queryObject.keySet()) {
                    ArrayList<String> list = new ArrayList<>();
                    try {
                        JSONArray array = queryObject.getJSONArray(key);
                        for (int i=0; i<array.length(); i++) {
                            list.add(array.optString(i));
                        }
                    } catch (JSONException e) {
                        list.add(queryObject.optString(key));
                    }
                    queryMap.put(key, list);
                }
            }

            if (operation != null) {
                String uuid = this.getHeaderString(headers, MessageInterface.HEADER_MESSAGEID);
                final String authorization = this.getHeaderString(headers, MessageInterface.HEADER_AUTHORIZATION);
                if (operationName != null) {
                    String path = operation.path;
                    if (path.contains("[uuid]")) {
                        if (uuid == null) {
                            return Util.futureError(new IllegalArgumentException("Operation '" + operationName + "' requires a UUID to be set in the AMQP header '" + MessageInterface.HEADER_MESSAGEID + "'"));
                        }
                        path = path.replace("[uuid]", uuid);
                    }
                    URL url;

                    try {
                        if (queryMap == null) {
                            url = this.getURLforPath(path);
                        } else {
                            StringJoiner parameters = new StringJoiner("&");
                            for (String key : queryMap.keySet()) {
                                ArrayList<String> list = queryMap.get(key);
                                for (String item : list) {
                                    parameters.add(key + "=" + item);
                                }
                            }
                            url = new URI(this.url.getProtocol(), null, this.url.getHost(), this.url.getPort(), path, parameters.toString(), null).toURL();
                        }
                    } catch (MalformedURLException e) {
                        return Util.futureError(e);
                    } catch (URISyntaxException e) {
                        return Util.futureError(e);
                    }
                    if (url != null) {
                        final String method = operation.method.toString();
                        final URL finalUrl = url;
                        final char[] data = jsonObject.toString().toCharArray();
                        return this.pool.submit(new Callable<String>() {
                            public String call() throws IOException {
                                String response = rest(method, finalUrl, data, authorization);
                                return response;
                            }
                        });
                    } else {
                       // return Util.futureError()
                    }
                }
            }
        }
        return null;
    }

    private URL getURLforPath(String path) throws MalformedURLException {
        return new URL(this.url.getProtocol(), this.url.getHost(), this.url.getPort(), path);
    }

    private String rest(String method, String path, char[] payload) throws IOException {
        return this.rest(method, path, payload, null);
    }

    private String rest(String method, String path, char[] payload, String authorization) throws IOException {
        return this.rest(method, this.getURLforPath(path), payload, authorization);
    }
    private String rest(String method, URL url, char[] payload, String authorization) throws IOException {
        HttpURLConnection connection = (HttpURLConnection) url.openConnection();
        connection.setRequestMethod(method);

        connection.setDoOutput(true);
        connection.setRequestProperty("Content-type", "application/json");
        if (authorization != null && !authorization.isEmpty()) {
            connection.setRequestProperty("Authorization", authorization);
        }
        System.out.println("Sending message to REST interface: " + method + " " + url.toString());
        try {
            if (!("GET".equalsIgnoreCase(method))) {
                OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
                out.write(payload);
                out.close();
            }
            return IOUtils.toString(connection.getInputStream());
        } catch (ConnectException e) {
            System.err.println("The defined REST interface ("+method+" "+connection.getURL().getHost() + ":" + connection.getURL().getPort() + connection.getURL().getPath()+") does not answer.");
            throw e;
        }
    }
}
