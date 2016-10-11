package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.*;
import dk.magenta.mox.agent.exceptions.InvalidObjectTypeException;
import dk.magenta.mox.agent.exceptions.InvalidOperationException;
import dk.magenta.mox.agent.json.JSONArray;
import dk.magenta.mox.agent.json.JSONObject;
import dk.magenta.mox.agent.messages.Headers;
import dk.magenta.mox.agent.messages.Message;
import dk.magenta.mox.agent.rest.RestClient;
import org.apache.log4j.Logger;

import java.io.IOException;
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
    public Logger log = Logger.getLogger(RestMessageHandler.class);
    private RestClient restClient;
    private Map<String, ObjectType> objectTypes;
    private final ExecutorService pool = Executors.newFixedThreadPool(10);

    public RestMessageHandler(String host, Map<String, ObjectType> objectTypes) throws MalformedURLException {
        this(new URL(host), objectTypes);
    }

    public RestMessageHandler(URL host, Map<String, ObjectType> objectTypes) throws MalformedURLException {
        this.restClient = new RestClient(new URL(host.getProtocol(),
                host.getHost(),
                host.getPort(), "/"));
        this.objectTypes = objectTypes;
    }

    public Future<String> run(Headers headers, JSONObject jsonObject) {
        this.log.info("Parsing message");
        try {
            String objectTypeName = headers.getString(Message.HEADER_OBJECTTYPE).toLowerCase();
            this.log.info("objectTypeName: " + objectTypeName);
            String operationName = headers.getString(Message.HEADER_OPERATION).toLowerCase();
            this.log.info("operationName: " + operationName);

            ObjectType objectType = this.objectTypes.get(objectTypeName);
            if (objectType == null) {
                throw new InvalidObjectTypeException(objectTypeName);
            } else {
                ObjectType.Operation operation = objectType.getOperation(operationName);
                if (operation == null) {
                    throw new InvalidOperationException(operationName);
                } else {

                    String query = headers.optString(Message.HEADER_QUERY);
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
                            } catch (org.json.JSONException e) {
                                list.add(queryObject.optString(key));
                            }
                            queryMap.put(key, list);
                        }
                    }

                    final String authorization = headers.optString(Message.HEADER_AUTHORIZATION);
                    if (operationName != null) {
                        String path = operation.path;
                        if (path.contains("[uuid]")) {
                            String uuid = headers.optString(Message.HEADER_OBJECTID);
                            if (uuid == null) {
                                throw new IllegalArgumentException("Operation '" + operationName + "' requires a UUID to be set in the AMQP header '" + Message.HEADER_OBJECTID + "'");
                            }
                            path = path.replace("[uuid]", uuid);
                        }
                        URL url;

                        try {
                            if (queryMap == null) {
                                url = restClient.getURLforPath(path);
                            } else {
                                StringJoiner parameters = new StringJoiner("&");
                                for (String key : queryMap.keySet()) {
                                    ArrayList<String> list = queryMap.get(key);
                                    for (String item : list) {
                                        parameters.add(key + "=" + item);
                                    }
                                }
                                url = new URI(this.restClient.url.getProtocol(), null, this.restClient.url.getHost(), this.restClient.url.getPort(), path, parameters.toString(), null).toURL();
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
                                    response = restClient.rest(method, finalUrl, data, authorization);
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
}
