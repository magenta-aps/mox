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
        moxTest.run();
        System.exit(0);
    }

    public MoxTest(String[] args) {
        super(args);
    }

    public void run() {
        try {
            this.sender = this.createMessageSender();
            this.testFacet();
            this.testKlassifikation();
            this.testKlasse();
            this.testItsystem();
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
    }

    //--------------------------------------------------------------------------

    private void testFacet() {
        if (this.sender != null) {
            try {
                UUID facet = this.testFacetOpret();
                if (facet != null) {
                    try {
                        this.testFacetRead(facet);
                        this.testFacetSearch();
                        this.testFacetList(facet);
                        this.testFacetUpdate(facet);
                        this.testFacetPassivate(facet);
                    } catch (TestException e) {
                    }
                    this.testFacetDelete(facet);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testFacetOpret() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating facet");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "facet");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/facet/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Facet created, uuid: "+uuid.toString());
            System.out.println("Create succeeded");
            return uuid;
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testFacetRead(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading facet, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "facet", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);
            JSONObject expected = getJSONObjectFromFilename("data/facet/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
                System.out.println("Read succeeded");
            } else {
                System.out.println("Result differs from the expected");
                throw new TestException();
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testFacetSearch() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for facet");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/facet/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "facet", query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            ArrayList<UUID> results = new ArrayList<>();
            JSONArray array;
            try {
                JSONObject object = new JSONObject(response);
                array = object.getJSONArray("results");
            } catch (JSONException e) {
                System.out.println(response);
                throw new TestException(e);
            }
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            if (results.size()>0) {
                System.out.println("Search succeeded");
            }
            return results;
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testFacetList(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing facets");
            Message message = new ListDocumentMessage(this.getAuthToken(), "facet", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONArray array;
                JSONObject object = new JSONObject(response);
                array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                if (uuid.toString().equals(item.getString("id"))) {
                    JSONObject expected = getJSONObjectFromFilename("data/facet/read_response.json");
                    // Update run-specific pieces of the object
                    expected.put("id", uuid.toString());
                    String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                    expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                    if (item.similar(expected)) {
                        System.out.println("List succeeded");
                    } else {
                        throw new TestException("Unexpected answer '" + item.toString() + "' (expected '"+expected.toString()+"')");
                    }
                }
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testFacetUpdate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating facet, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "facet", uuid, getJSONObjectFromFilename("data/facet/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testFacetPassivate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating facet, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "facet", uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testFacetDelete(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting facet, uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), "facet", uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);

            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Delete succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    //--------------------------------------------------------------------------

    private void testKlassifikation() {
        if (this.sender != null) {
            try {
                UUID klassifikation = this.testKlassifikationOpret();
                if (klassifikation != null) {
                    try {
                        this.testKlassifikationRead(klassifikation);
                        this.testKlassifikationSearch();
                        this.testKlassifikationList(klassifikation);
                        this.testKlassifikationUpdate(klassifikation);
                        this.testKlassifikationPassivate(klassifikation);
                    } catch (TestException e) {
                    }
                    this.testKlassifikationDelete(klassifikation);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testKlassifikationOpret() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating klassifikation");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "klassifikation");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/klassifikation/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Klassifikation created, uuid: "+uuid.toString());
            System.out.println("Create succeeded");
            return uuid;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassifikationRead(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading klassifikation, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "klassifikation", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);

            JSONObject expected = getJSONObjectFromFilename("data/klassifikation/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
                System.out.println("Read succeeded");
            } else {
                System.out.println("Result differs from the expected");
                throw new TestException();
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testKlassifikationSearch() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for klassifikation");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/klassifikation/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "klassifikation", query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            ArrayList<UUID> results = new ArrayList<>();
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");

            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            if (results.size()>0) {
                System.out.println("Search succeeded");
            }
            return results;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassifikationList(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing klassifikations");
            Message message = new ListDocumentMessage(this.getAuthToken(), "klassifikation", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                if (uuid.toString().equals(item.getString("id"))) {
                    JSONObject expected = getJSONObjectFromFilename("data/klassifikation/read_response.json");
                    // Update run-specific pieces of the object
                    expected.put("id", uuid.toString());
                    String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                    expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                    if (item.similar(expected)) {
                        System.out.println("List succeeded");
                    } else {
                        throw new TestException("Unexpected answer '" + item.toString() + "' (expected '"+expected.toString()+"')");
                    }
                }
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassifikationUpdate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating klassifikation, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "klassifikation", uuid, getJSONObjectFromFilename("data/klassifikation/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));

            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassifikationPassivate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating klassifikation, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "klassifikation", uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
            }

        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassifikationDelete(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting klassifikation, uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), "klassifikation", uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Delete succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    //--------------------------------------------------------------------------

    private void testKlasse() {
        if (this.sender != null) {
            try {
                UUID klasse = this.testKlasseOpret();
                if (klasse != null) {
                    try {
                        this.testKlasseRead(klasse);
                        this.testKlasseSearch();
                        this.testKlasseList(klasse);
                        this.testKlasseUpdate(klasse);
                        this.testKlassePassivate(klasse);
                    } catch (TestException e) {
                    }
                    this.testKlasseDelete(klasse);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testKlasseOpret() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating klasse");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "klasse");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/klasse/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Klasse created, uuid: "+uuid.toString());
            System.out.println("Create succeeded");
            return uuid;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlasseRead(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading klasse, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "klasse", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);

            JSONObject expected = getJSONObjectFromFilename("data/klasse/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
                System.out.println("Read succeeded");
            } else {
                System.out.println("Result differs from the expected");
                throw new TestException();
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testKlasseSearch() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for klasse");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/klasse/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "klasse", query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            ArrayList<UUID> results = new ArrayList<>();
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");

            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            if (results.size()>0) {
                System.out.println("Search succeeded");
            }
            return results;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlasseList(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing klasses");
            Message message = new ListDocumentMessage(this.getAuthToken(), "klasse", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                if (uuid.toString().equals(item.getString("id"))) {
                    JSONObject expected = getJSONObjectFromFilename("data/klasse/read_response.json");
                    // Update run-specific pieces of the object
                    expected.put("id", uuid.toString());
                    String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                    expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                    if (item.similar(expected)) {
                        System.out.println("List succeeded");
                    } else {
                        throw new TestException("Unexpected answer '" + item.toString() + "' (expected '"+expected.toString()+"')");
                    }
                }
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlasseUpdate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating klasse, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "klasse", uuid, getJSONObjectFromFilename("data/klasse/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));

            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlassePassivate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating klasse, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "klasse", uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
            }

        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testKlasseDelete(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting klasse, uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), "klasse", uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Delete succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    //--------------------------------------------------------------------------

    private void testItsystem() {
        if (this.sender != null) {
            try {
                UUID itsystem = this.testItsystemOpret();
                if (itsystem != null) {
                    try {
                        this.testItsystemRead(itsystem);
                        this.testItsystemSearch();
                        this.testItsystemList(itsystem);
                        this.testItsystemUpdate(itsystem);
                        this.testItsystemPassivate(itsystem);
                    } catch (TestException e) {
                    }
                    this.testItsystemDelete(itsystem);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testItsystemOpret() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating itsystem");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "itsystem");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/itsystem/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Itsystem created, uuid: "+uuid.toString());
            System.out.println("Create succeeded");
            return uuid;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testItsystemRead(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading itsystem, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "itsystem", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);

            JSONObject expected = getJSONObjectFromFilename("data/itsystem/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
                System.out.println("Read succeeded");
            } else {
                System.out.println("Result differs from the expected");
                throw new TestException();
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testItsystemSearch() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for itsystem");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/itsystem/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "itsystem", query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            ArrayList<UUID> results = new ArrayList<>();
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");

            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            if (results.size()>0) {
                System.out.println("Search succeeded");
            }
            return results;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testItsystemList(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing itsystems");
            Message message = new ListDocumentMessage(this.getAuthToken(), "itsystem", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                if (uuid.toString().equals(item.getString("id"))) {
                    JSONObject expected = getJSONObjectFromFilename("data/itsystem/read_response.json");
                    // Update run-specific pieces of the object
                    expected.put("id", uuid.toString());
                    String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                    expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                    if (item.similar(expected)) {
                        System.out.println("List succeeded");
                    } else {
                        throw new TestException("Unexpected answer '" + item.toString() + "' (expected '"+expected.toString()+"')");
                    }
                }
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testItsystemUpdate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating itsystem, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "itsystem", uuid, getJSONObjectFromFilename("data/itsystem/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));

            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testItsystemPassivate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating itsystem, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "itsystem", uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
            }

        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testItsystemDelete(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting itsystem, uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), "itsystem", uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Delete succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    //--------------------------------------------------------------------------

    private void testBruger() {
        if (this.sender != null) {
            try {
                UUID bruger = this.testBrugerOpret();
                if (bruger != null) {
                    try {
                        this.testBrugerRead(bruger);
                        this.testBrugerSearch();
                        this.testBrugerList(bruger);
                        this.testBrugerUpdate(bruger);
                        this.testBrugerPassivate(bruger);
                    } catch (TestException e) {
                    }
                    this.testBrugerDelete(bruger);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testBrugerOpret() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating bruger");
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "bruger");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/bruger/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            System.out.println("Bruger created, uuid: "+uuid.toString());
            System.out.println("Create succeeded");
            return uuid;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating");
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testBrugerRead(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading bruger, uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), "bruger", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            System.out.println(response);
            JSONObject object = new JSONObject(response);
            JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);

            JSONObject expected = getJSONObjectFromFilename("data/bruger/read_response.json");

            // Update run-specific pieces of the object
            expected.put("id", uuid.toString());
            String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
            expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

            if (item.similar(expected)) {
                System.out.println("Expected response received");
                System.out.println("Read succeeded");
            } else {
                System.out.println("Result differs from the expected");
                throw new TestException();
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testBrugerSearch() throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for bruger");
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/bruger/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), "bruger", query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            ArrayList<UUID> results = new ArrayList<>();
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");

            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                results.add(UUID.fromString(array.getString(i)));
            }
            System.out.println(results.size() + " items found");
            if (results.size()>0) {
                System.out.println("Search succeeded");
            }
            return results;
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testBrugerList(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing brugers");
            Message message = new ListDocumentMessage(this.getAuthToken(), "bruger", uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            JSONArray array = object.getJSONArray("results");
            try {
                array = array.getJSONArray(0);
            } catch (JSONException e) {}
            for (int i=0; i<array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                if (uuid.toString().equals(item.getString("id"))) {
                    JSONObject expected = getJSONObjectFromFilename("data/bruger/read_response.json");
                    // Update run-specific pieces of the object
                    expected.put("id", uuid.toString());
                    String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                    expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                    if (item.similar(expected)) {
                        System.out.println("List succeeded");
                    } else {
                        throw new TestException("Unexpected answer '" + item.toString() + "' (expected '"+expected.toString()+"')");
                    }
                }
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testBrugerUpdate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating bruger, uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), "bruger", uuid, getJSONObjectFromFilename("data/bruger/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));

            if (uuid.compareTo(result) == 0) {
                System.out.println("Update succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.print(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testBrugerPassivate(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating bruger, uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), "bruger", uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Passivate succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
            }

        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testBrugerDelete(UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting bruger, uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), "bruger", uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            JSONObject object = new JSONObject(response);
            UUID result = UUID.fromString(object.getString("uuid"));
            if (uuid.compareTo(result) == 0) {
                System.out.println("Delete succeeded");
            } else {
                throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '"+uuid.toString()+"')");
            }
        } catch (JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    //--------------------------------------------------------------------------

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
