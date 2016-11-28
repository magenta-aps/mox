package dk.magenta.mox.test;

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;
import dk.magenta.mox.agent.ParameterMap;
import dk.magenta.mox.agent.json.JSONArray;
import dk.magenta.mox.agent.json.JSONObject;
import dk.magenta.mox.agent.messages.*;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.*;
import java.net.ConnectException;
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
        // Preliminary checks:
        // Is RabbitMQ reachable?
        try {
            this.sender = this.createMessageSender();
        } catch (ConnectException e) {
            System.out.println("RabbitMQ server is not reachable with the given configuration");
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }

        // TODO: Is MoxRestFrontend running?

        if (this.sender != null) {
            this.test("facet");
            this.test("klassifikation");
            this.test("klasse");
            this.test("itsystem");
            this.test("bruger");
        }
    }

    //--------------------------------------------------------------------------


    private void test(String name) {
        if (this.sender != null) {
            try {
                UUID item = this.testOpret(name);
                if (item != null) {
                    try {
                        this.testRead(name, item);
                        this.testSearch(name);
                        this.testList(name, item);
                        this.testUpdate(name, item);
                        this.testPassivate(name, item);
                    } catch (TestException e) {
                    }
                    this.testDelete(name, item);
                }
            } catch (TestException e) {
                e.printStackTrace();
            }
        }
    }

    private UUID testOpret(String name) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Creating "+name);
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, name);
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("data/"+name+"/create.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONObject object = new JSONObject(response);
                UUID uuid = UUID.fromString(object.getString("uuid"));
                System.out.println(name + " created, uuid: " + uuid.toString());
                System.out.println("Create succeeded");
                return uuid;
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            System.out.println("Failed creating "+name);
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testRead(String name, UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Reading "+name+", uuid: "+uuid.toString());
            Message message = new ReadDocumentMessage(this.getAuthToken(), name, uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONObject object = new JSONObject(response);
                JSONObject item = object.getJSONArray(uuid.toString()).getJSONObject(0);
                JSONObject expected = getJSONObjectFromFilename("data/" + name + "/read_response.json");

                // Update run-specific pieces of the object
                expected.put("id", uuid.toString());
                String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                JSONObject firstReg = expected.getJSONArray("registreringer").getJSONObject(0);
                firstReg.getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);

                if (item.similar(expected)) {
                    System.out.println("Expected response received");
                    System.out.println("Read succeeded");
                } else {
                    System.out.println("Result differs from the expected");
                    System.out.println(item.toString());
                    System.out.println(expected.toString());
                    throw new TestException();
                }
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private List<UUID> testSearch(String name) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Searching for "+name);
            ParameterMap<String, String> query = new ParameterMap<>();
            query.populateFromJSON(getJSONObjectFromFilename("data/"+name+"/search.json"));
            Message message = new SearchDocumentMessage(this.getAuthToken(), name, query);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                ArrayList<UUID> results = new ArrayList<>();
                JSONArray array;
                try {
                    JSONObject object = new JSONObject(response);
                    array = object.getJSONArray("results");
                } catch (org.json.JSONException e) {
                    System.out.println(response);
                    throw new TestException(e);
                }
                try {
                    array = array.getJSONArray(0);
                } catch (org.json.JSONException e) {
                }
                for (int i = 0; i < array.length(); i++) {
                    results.add(UUID.fromString(array.getString(i)));
                }
                System.out.println(results.size() + " items found");
                if (results.size() > 0) {
                    System.out.println("Search succeeded");
                }
                return results;
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testList(String name, UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Listing "+name+" items");
            Message message = new ListDocumentMessage(this.getAuthToken(), name, uuid);
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONArray array;
                JSONObject object = new JSONObject(response);
                array = object.getJSONArray("results");
                try {
                    array = array.getJSONArray(0);
                } catch (org.json.JSONException e) {
                }
                for (int i = 0; i < array.length(); i++) {
                    JSONObject item = array.getJSONObject(i);
                    if (uuid.toString().equals(item.getString("id"))) {
                        JSONObject expected = getJSONObjectFromFilename("data/" + name + "/read_response.json");
                        // Update run-specific pieces of the object
                        expected.put("id", uuid.toString());
                        String timestamp = item.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").getString("tidsstempeldatotid");
                        expected.getJSONArray("registreringer").getJSONObject(0).getJSONObject("fratidspunkt").put("tidsstempeldatotid", timestamp);
                        if (item.similar(expected)) {
                            System.out.println("List succeeded");
                        } else {
                            throw new TestException("Unexpected answer '" + item.toString() + "' (expected '" + expected.toString() + "')");
                        }
                    }
                }
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testUpdate(String name, UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Updating "+name+", uuid: "+uuid.toString());
            Message message = new UpdateDocumentMessage(this.getAuthToken(), name, uuid, getJSONObjectFromFilename("data/"+name+"/update.json"));
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONObject object = new JSONObject(response);
                UUID result = UUID.fromString(object.getString("uuid"));
                if (uuid.compareTo(result) == 0) {
                    System.out.println("Update succeeded");
                } else {
                    throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
                }
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testPassivate(String name, UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Passivating "+name+", uuid: "+uuid.toString());
            Message message = new PassivateDocumentMessage(this.getAuthToken(), name, uuid, "Passivate, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONObject object = new JSONObject(response);
                UUID result = UUID.fromString(object.getString("uuid"));
                if (uuid.compareTo(result) == 0) {
                    System.out.println("Passivate succeeded");
                } else {
                    throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
                }
            }
        } catch (org.json.JSONException e) {
            System.out.println(response);
            throw new TestException(e);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
            throw new TestException(e);
        }
    }

    private void testDelete(String name, UUID uuid) throws TestException {
        String response = null;
        try {
            printDivider();
            System.out.println("Deleting "+name+", uuid: "+uuid.toString());
            Message message = new DeleteDocumentMessage(this.getAuthToken(), name, uuid, "Delete, please");
            response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            if (response == null) {
                throw new TestException("Got null response from sender");
            } else {
                JSONObject object = new JSONObject(response);
                UUID result = UUID.fromString(object.getString("uuid"));
                if (uuid.compareTo(result) == 0) {
                    System.out.println("Delete succeeded");
                } else {
                    throw new TestException("Unexpected answer '" + object.getString("uuid") + "' (expected '" + uuid.toString() + "')");
                }
            }
        } catch (org.json.JSONException e) {
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

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws IOException, org.json.JSONException {
        return new JSONObject(new FileInputStream(new File(jsonFilename)));
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
