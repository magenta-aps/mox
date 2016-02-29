package dk.magenta.mox.test;

import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;
import dk.magenta.mox.agent.messages.CreateDocumentMessage;
import dk.magenta.mox.agent.messages.Headers;
import dk.magenta.mox.agent.messages.Message;
import dk.magenta.mox.agent.messages.ReadDocumentMessage;
import org.apache.commons.io.IOUtils;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
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

            this.testFacetOpret();
        } catch (IOException | TimeoutException e) {
            e.printStackTrace();
        }
    }

    private UUID testFacetOpret() {
        try {
            Headers headers = this.getBaseHeaders();
            headers.put(Message.HEADER_OBJECTTYPE, "facet");
            headers.put(Message.HEADER_OPERATION, CreateDocumentMessage.OPERATION);
            JSONObject payload = getJSONObjectFromFilename("test/facet_opret.json");
            Message message = CreateDocumentMessage.parse(headers, payload);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            System.out.println("Response: "+response);
            JSONObject object = new JSONObject(response);
            UUID uuid = UUID.fromString(object.getString("uuid"));
            return uuid;
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
            e.printStackTrace();
        }
        return null;
    }

    private void testFacetRead(UUID uuid) {
        try {
            Message message = new ReadDocumentMessage(this.getAuthToken(), "facet", uuid);
            String response = this.sender.send(message, true).get(30, TimeUnit.SECONDS);
            System.out.println("Response: "+response);
        } catch (InterruptedException | IOException | ExecutionException | TimeoutException e) {
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

}
