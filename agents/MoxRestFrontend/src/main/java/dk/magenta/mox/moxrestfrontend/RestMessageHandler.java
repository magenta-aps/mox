package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.*;
import dk.magenta.mox.agent.exceptions.InvalidObjectTypeException;
import dk.magenta.mox.agent.exceptions.InvalidOperationException;
import dk.magenta.mox.agent.messages.Headers;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
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
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

public class RestMessageHandler implements MessageHandler {

    private URL url;
    private Map<String, ObjectType> objectTypes;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);
    protected Logger log = Logger.getLogger(RestMessageHandler.class);

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

    public Future<String> run(Headers headers, JSONObject jsonObject) {
        this.log.info("Parsing message");
        try {
            String objectTypeName = headers.getString(MessageInterface.HEADER_OBJECTTYPE).toLowerCase();
            this.log.info("objectTypeName: " + objectTypeName);
            String operationName = headers.getString(MessageInterface.HEADER_OPERATION).toLowerCase();
            this.log.info("operationName: " + operationName);

            ObjectType objectType = this.objectTypes.get(objectTypeName);
            if (objectType == null) {
                throw new InvalidObjectTypeException(objectTypeName);
            } else {
                ObjectType.Operation operation = objectType.getOperation(operationName);
                if (operation == null) {
                    throw new InvalidOperationException(operationName);
                } else {

                    String query = headers.optString(MessageInterface.HEADER_QUERY);
                    HashMap<String, ArrayList<String>> queryMap = null;
                    if (query != null) {
                        this.log.info("query: " + query);
                        JSONObject queryObject = new JSONObject(query);
                        queryMap = new HashMap<>();
                        for (String key : queryObject.keySet()) {
                            ArrayList<String> list = new ArrayList<>();
                            try {
                                JSONArray array = queryObject.getJSONArray(key);
                                for (int i = 0; i < array.length(); i++) {
                                    list.add(array.optString(i));
                                }
                            } catch (JSONException e) {
                                list.add(queryObject.optString(key));
                            }
                            queryMap.put(key, list);
                        }
                    }

                    final String authorization = headers.optString(MessageInterface.HEADER_AUTHORIZATION);
                    if (operationName != null) {
                        String path = operation.path;
                        if (path.contains("[uuid]")) {
                            String uuid = headers.optString(MessageInterface.HEADER_MESSAGEID);
                            if (uuid == null) {
                                throw new IllegalArgumentException("Operation '" + operationName + "' requires a UUID to be set in the AMQP header '" + MessageInterface.HEADER_MESSAGEID + "'");
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
                        this.log.info("Calling REST interface at " + url.toString());
                        final String method = operation.method.toString();
                        final URL finalUrl = url;
                        final char[] data = jsonObject.toString().toCharArray();
                        return this.pool.submit(new Callable<String>() {
                            public String call() {
                                String response = null;
                                try {
                                    response = rest(method, finalUrl, data, authorization);
                                } catch (IOException e) {
                                    response = Util.error(e);
                                }
                                RestMessageHandler.this.log.info("Response: " + response);
                                return response;
                            }
                        });
                    }
                }
            }
            return null;
        } catch (Exception e) {
            this.log.error(e);
            return Util.futureError(e);
        }
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
        connection.setConnectTimeout(30000);

        connection.setDoOutput(true);
        connection.setRequestProperty("Content-type", "application/json");
        if (authorization != null && !authorization.isEmpty()) {
            connection.setRequestProperty("Authorization", authorization.trim());
        }
        this.log.info("Sending message to REST interface: " + method + " " + url.toString());
        System.out.println("Sending message to REST interface: " + method + " " + url.toString() + " " + new String(payload));
        try {
            if (!("GET".equalsIgnoreCase(method))) {
                OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
                out.write(payload);
                out.close();
            }
            String response = IOUtils.toString(connection.getInputStream());
            this.log.info("got response");
            return response;
        } catch (ConnectException e) {
            this.log.warn("The defined REST interface ("+method+" "+connection.getURL().getHost() + ":" + connection.getURL().getPort() + connection.getURL().getPath()+") does not answer.");
            throw e;
        } catch (IOException e) {
            this.log.warn("IOException on request to "+method+" "+url.toString()+": "+e.getMessage());
            throw e;
        }
    }
}
