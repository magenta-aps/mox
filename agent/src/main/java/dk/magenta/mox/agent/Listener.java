package dk.magenta.mox.agent;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import java.io.*;
import java.net.MalformedURLException;
import java.util.*;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 06-08-15.
 */
public class Listener {

    public static void main(String[] args) {

        String queueInterface = null;
        String queueName = null;
        String restInterface = null;

        HashMap<String, String> argMap = new HashMap<String, String>();
        String paramKey = null;
        for (String arg : args) {
            arg = arg.trim();
            if (arg.startsWith("--")) {
                arg = arg.substring(1);
                paramKey = arg;
            } else if (!arg.isEmpty()) {
                if (paramKey != null) {
                    argMap.put(paramKey, arg);
                    paramKey = null;
                }
            }
        }


        System.out.println("Reading command line arguments");
        if (argMap.containsKey("queueInterface")) {
            queueInterface = argMap.get("queueInterface");
            System.out.println("    queueInterface = " + queueInterface);
        }

        if (argMap.containsKey("queueName")) {
            queueName = argMap.get("queueName");
            System.out.println("    queueName = " + queueName);
        }

        if (argMap.containsKey("restInterface")) {
            restInterface = argMap.get("restInterface");
            System.out.println("    restInterface = " + restInterface);
        }

        String propertiesFilename = argMap.get("p");
        File propertiesFile;

        if (propertiesFilename == null) {
            propertiesFilename = "agent.properties";
            propertiesFile = new File(propertiesFilename);
            if (!propertiesFile.canRead()) {
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
        if (propertiesFile.canRead()) {
            Properties properties = new Properties();
            try {
                properties.load(new FileInputStream(propertiesFile));
            } catch (IOException e) {
                System.err.println("Error loadling from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                return;
            }
            System.out.println("Reading properties file " + propertiesFile.getAbsolutePath());

            if (queueInterface == null) {
                queueInterface = properties.getProperty("queueInterface");
                System.out.println("    queueInterface = " + queueInterface);
            }
            if (queueName == null) {
                queueName = properties.getProperty("queueName");
                System.out.println("    queueName = " + queueName);
            }
            if (restInterface == null) {
                restInterface = properties.getProperty("restInterface");
                System.out.println("    restInterface = " + restInterface);
            }
        }



        System.out.println("Loading defaults");

        if (queueInterface == null) {
            queueInterface = "localhost:5672";
            System.out.println("    queueInterface = " + queueInterface);
        }
        if (queueName == null) {
            queueName = "incoming";
            System.out.println("    queueName = " + queueName);
        }
        if (restInterface == null) {
            restInterface = "http://127.0.0.1:5000";
            System.out.println("    restInterface = " + restInterface);
        }

        try {
            Map<String, ObjectType> objectTypes = ObjectType.load(propertiesFile);

            System.out.println("Listening for messages from RabbitMQ service at " + queueInterface + ", queue name '" + queueName + "'");
            System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + restInterface);
            MessageReceiver messageReceiver = new MessageReceiver(queueInterface, null, queueName, true);
            try {
                messageReceiver.run(new RestMessageHandler(restInterface, objectTypes));
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            messageReceiver.close();

            MessageSender notifier = new MessageSender(queueInterface, null, "notifications");
            notifier.sendFromGenerator(new DummyMessageGenerator());


        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }
}
