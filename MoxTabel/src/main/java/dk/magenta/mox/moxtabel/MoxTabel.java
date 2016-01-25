package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 25-01-16.
 */
public class MoxTabel extends MoxAgent {

    private AmqpDefinition listenerDefinition;
    private AmqpDefinition senderDefinition;

    public static void main(String[] args) {
        MoxTabel agent = new MoxTabel(args);
        agent.run();
    }

    public MoxTabel(String[] args) {
        super(args);

        String listenerPrefix = "amqp.incoming";
        String senderPrefix = "amqp.outgoing";


        HashMap<String, String> argMap = new HashMap<String, String>();
        for (String arg : args) {
            arg = arg.trim();
            if (arg.startsWith("-")) {
                arg = arg.substring(2);
                String[] keyVal = arg.split("=", 2);
                if (keyVal.length != 2) {
                    throw new IllegalArgumentException("Parameter " +
                            arg + " must be of the format -Dparam=value");
                }
                argMap.put(keyVal[0], keyVal[1]);
            }
        }


        File propertiesFile = new File("moxtabel.properties");
        String propertiesFilename = argMap.get("propertiesFile");

        if (propertiesFilename == null) {
            if (propertiesFile == null) {
                System.err.println("properties file not set");
                return;
            } else if (!propertiesFile.canRead()) {
                System.err.println("Cannot read from default properties file " + propertiesFile.getAbsolutePath());
                return;
            }
        } else {
            propertiesFile = new File(propertiesFilename);
            if (!propertiesFile.exists()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " does not exist");
                return;
            } else if (!propertiesFile.canRead()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " exist, but is unreadable by this user");
                return;
            }
        }

        this.listenerDefinition = new AmqpDefinition();
        this.listenerDefinition.populateFromMap(argMap, listenerPrefix, true, true);
        this.listenerDefinition.populateFromProperties(properties, listenerPrefix, false);
        this.listenerDefinition.populateFromDefaults(true, listenerPrefix);

        this.senderDefinition = new AmqpDefinition();
        this.senderDefinition.populateFromMap(argMap, senderPrefix, true, true);
        this.senderDefinition.populateFromProperties(properties, senderPrefix, false);
        this.senderDefinition.populateFromDefaults(true, senderPrefix);


    }

    protected String getDefaultPropertiesFileName() {
        return "moxtabel.properties";
    }

    @Override
    protected void run() {
        try {
            MessageReceiver receiver = new MessageReceiver(this.listenerDefinition, true);
            MessageSender sender = new MessageSender(this.senderDefinition);
            receiver.run(new UploadedDocumentMessageHandler(sender, this.objectTypes));
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

}
