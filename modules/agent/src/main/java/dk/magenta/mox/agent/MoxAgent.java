package dk.magenta.mox.agent;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 06-08-15.
 */
public class MoxAgent extends MoxAgentBase {

    private AmqpDefinition amqpDefinition;

    public AmqpDefinition getAmqpDefinition() {
        return amqpDefinition;
    }
    
    protected MoxAgent() {
        this.amqpDefinition = new AmqpDefinition();

        String prefix = "amqp";

        try {
            this.loadProperties();
            this.amqpDefinition.populateFromProperties(this.properties, prefix, false, true);
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.loadDefaults();
        this.amqpDefinition.populateFromDefaults(true, prefix);
    }

    public MoxAgent(String[] args) {

        this.amqpDefinition = new AmqpDefinition();
        String prefix = "amqp";

        this.loadArgs(args);
        this.amqpDefinition.populateFromMap(this.commandLineArgs, prefix, true, true);

        try {
            this.loadProperties();
            this.amqpDefinition.populateFromProperties(this.properties, prefix, false, true);
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.loadDefaults();
        this.amqpDefinition.populateFromDefaults(true, prefix);
    }
    
    protected MessageReceiver createMessageReceiver() throws IOException, TimeoutException {
        return new MessageReceiver(this.amqpDefinition, true);
    }

    protected MessageSender createMessageSender() throws IOException, TimeoutException {
        return new MessageSender(this.amqpDefinition);
    }

    public void run() {
    }

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }

    protected void shutdown() {

    }
}
