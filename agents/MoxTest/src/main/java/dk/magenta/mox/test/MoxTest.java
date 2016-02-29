package dk.magenta.mox.test;

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;
import dk.magenta.mox.agent.ParameterMap;
import dk.magenta.mox.agent.messages.*;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class MoxTest extends MoxAgent {

    private Logger log = Logger.getLogger(MoxTest.class);
    private MessageSender sender;
    private String authToken;

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxTest moxTest = new MoxTest(args);
    }

    public MoxTest(String[] args) {
        super(args);
        try {
            this.sender = this.createMessageSender();

            UUID facet = this.testFacetOpret();
            if (facet != null) {
                this.testFacetRead(facet);
                this.testFacetSearch();
                this.testFacetUpdate(facet);
                this.testFacetPassivate(facet);
            }
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
        System.exit(0);
    }

    private UUID testFacetOpret() {
        try {
            printDivider();
            System.out.println("Creating facet");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "facet");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/facet/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Facet created, uuid: "+uuid.toString());
            return uuid;
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException | JSONException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
        }
        return null;
    }

    private void testFacetRead(UUID uuid) {
        try {
            printDivider();
            System.out.println("Reading facet, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "facet", uuid);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);
            JSONObject expected = getJSONObjectFromFilename("data/facet/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
            } else {
                System.out.println("Result differs from the expected");
            }
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException | JSONException e) {
            e.printStackTrace();
        }
    }

    private List<UUID> testFacetSearch() {
        try {
            printDivider();
            System.out.println("Searching for facet");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/facet/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "facet", query);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            ArrayList<UUID> results = new ArrayList<>();
            JSONArray array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            return results;
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException | JSONException e) {
            e.printStackTrace();
        }
        return null;
    }

    private void testFacetUpdate(UUID uuid) {
        try {
            printDivider();
            System.out.println("Updating facet, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "facet", uuid, getJSONObjectFromFilename("data/facet/update.json"));
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            }
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException | JSONException e) {
            e.printStackTrace();
        }
    }

    private void testFacetPassivate(UUID uuid) {
        try {
            printDivider();
            System.out.println("Passivating facet, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "facet", uuid);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            }
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException | JSONException e) {
            e.printStackTrace();
        }
    }

    private Headers getBaseHeaders() {
        Headers headers = new Headers();
        headers.put(Message.HEADER_AUTHORIZATION, this.getAuthToken());
        return headers;
    }

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }

    private String getAuthToken() {
        if (this.authToken == null) {
            try {
                System.out.println("Getting authtoken");
                Process authProcess = Runtime.getRuntime().exec(this.properties.getProperty("auth.command"));
                InputStream processOutput = authProcess.getInputStream();
                StringWriter writer = new StringWriter();
                IOUtils.copy(processOutput, writer);
                String output = writer.toString();
                String tokentype = this.properties.getProperty("auth.tokentype");
                if (tokentype != null) {
                    int index = output.indexOf(tokentype);
                    if (index != -1) {
                        int endIndex = output.indexOf("\n", index);
                        this.authToken = output.substring(index, endIndex).trim();
                        System.out.println("Authtoken obtained");
                    }
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        return this.authToken;
    }

    protected String getDefaultPropertiesFileName() {
        return "moxtest.properties";
    }

    private static void printDivider() {
        System.out.println("---------------------------");
    }

}
