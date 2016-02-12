package dk.magenta.mox.agent;

import com.rabbitmq.client.ConnectionFactory;

import org.apache.log4j.xml.DOMConfigurator;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

import javax.naming.OperationNotSupportedException;
import java.io.*;
import java.net.MalformedURLException;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 06-08-15.
 */
public class MoxAgent {
    public static Properties properties;

    String restInterface = null;

    private AmqpDefinition amqpDefinition;

    private File propertiesFile;

    public AmqpDefinition getAmqpDefinition() {
        return amqpDefinition;
    }

    public static Properties getProperties() {
        return properties;
    }

    protected Map<String, ObjectType> objectTypes;
    ArrayList<String> commands = new ArrayList<String>();


    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxAgent main = new MoxAgent(args);

        for (String arg : args) {
            if (arg.equalsIgnoreCase("help")) {
                main.printHelp();
                return;
            }
        }

        main.run();
    }

    protected MoxAgent() {
    }

    public MoxAgent(String[] args) {
        this.amqpDefinition = new AmqpDefinition();
        this.loadArgs(args);
        this.loadPropertiesFile();
        this.loadDefaults();
        this.loadObjectTypes();
    }

    protected String getDefaultPropertiesFileName() {
        return "agent.properties";
    }

    private void setPropertiesFile(String propertiesFileName) {
        this.propertiesFile = new File(propertiesFileName);
    }

    private void loadObjectTypes() {
        try {
            objectTypes = ObjectType.load(propertiesFile);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void printHelp() {
        System.out.println("Mox agent message interface");
        System.out.println("---------------------------");
        System.out.println("Will interface with a RabbitMQ message queue and pass messages through to a REST interface");
        System.out.println("Usage: java -cp \"target/moxagent-1.0.jar:target/dependency/*\" dk.magenta.mox.agent.Main [parameters] command\n");

        System.out.println("-----------");
        System.out.println("Parameters:\n");
        System.out.println("propertiesFile (-DpropertiesFile=<file>):\n    A Java properties file that contains configuration values.\n    Any parameters not found on the command line will be loaded from there.\n    Should also contain configuration for a SAML token service.\n    If this parameter is unset, the file 'agent.properties' will be loaded.\n");
        System.out.println("queueUsername (-DqueueUsername=<queueUsername>):\n    The RabbitMQ username.\n    If this is neither found in the command line or in the properties file, the value defaults to " + ConnectionFactory.DEFAULT_USER + ".\n");
        System.out.println("queuePassword (-DqueuePassword=<queuePassword>):\n    The RabbitMQ password.\n    If this is neither found in the command line or in the properties file, the value defaults to " + ConnectionFactory.DEFAULT_PASS + ".\n");
        System.out.println("queueInterface (-DqueueInterface=<hostname>:<port>):\n    An interface (<hostname>:<port>) where an instance of RabbitMQ is listening.\n    If this is neither found in the command line or in the properties file, the value defaults to localhost:5672.\n");
        System.out.println("queueName (-DqueueName=<name>):\n    The name of the RabbitMQ queue to send or receive messages in.\n    Defaults to 'incoming' if not found elsewhere.\n");
        System.out.println("restInterface (-DrestInterface=<protocol>://<hostname>:<port>):\n    The REST interface where messages should end up when passed through the queue.\n    Also needed for obtaining a SAML token for authenticating to that interface.\n    Defaults to http://127.0.0.1:5000\n");

        System.out.println("---------");
        System.out.println("Commands:\n");
        System.out.println("listen\n    Starts a listener agent, which reads from the defined queue and sends requests to the defined REST interface\n");
        System.out.println("send [operation] [objecttype] [jsonfile]\n    Sends a messsage to the queue, telling listeners to perform [operation] on [objecttype] with data from [jsonfile].\n    E.g. 'send create facet facet.json'\n");
        return;
    }

    protected void loadArgs(String[] commandlineArgs) {

        System.out.println("Reading command line arguments");

        HashMap<String, String> argMap = new HashMap<String, String>();
        try {
            for (String arg : commandlineArgs) {
                arg = arg.trim();
                if (arg.startsWith("-")) {
                    if (commands.size() > 0) {
                        throw new IllegalArgumentException("You cannot append parameters after the command arguments");
                    }
                    arg = arg.substring(2);
                    String[] keyVal = arg.split("=", 2);
                    if (keyVal.length != 2) {
                        throw new IllegalArgumentException("Parameter " +
                                arg + " must be of the format -Dparam=value");
                    }
                    argMap.put(keyVal[0], keyVal[1]);
                } else if (!arg.isEmpty()) {
                    commands.add(arg);
                }
            }
        } catch (IllegalArgumentException e) {
            e.printStackTrace();
            return;
        }

        this.amqpDefinition.populateFromMap(argMap, "amqp", true, true);

        if (argMap.containsKey("rest.interface")) {
            restInterface = argMap.get("rest.interface");
            System.out.println("    rest.interface = " + restInterface);
        }

        if (argMap.containsKey("stsAddress")) {
            properties.setProperty("security.sts.address", argMap.get("stsAddress"));
            System.out.println("    stsAddress = " + argMap.get("stsAddress"));
        }

        String propertiesFilename = argMap.get("propertiesFile");

        if (propertiesFilename == null) {
            String defaultPropertiesFilename = this.getDefaultPropertiesFileName();
            this.setPropertiesFile(defaultPropertiesFilename);
            if (propertiesFile == null) {
                System.err.println("properties file '"+defaultPropertiesFilename+"' not set");
                return;
            } else if (!propertiesFile.canRead()) {
                System.err.println("Cannot read from default properties file " + propertiesFile.getAbsolutePath());
                return;
            }
        } else {
            this.setPropertiesFile(propertiesFilename);
            if (!propertiesFile.exists()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " does not exist");
                return;
            } else if (!propertiesFile.canRead()) {
                System.err.println("Invalid parameter: properties file " + propertiesFile.getAbsolutePath() + " exist, but is unreadable by this user");
                return;
            }
        }
    }

    protected void loadPropertiesFile() {
        properties = new Properties();
        if (propertiesFile.canRead()) {
            try {
                properties.load(new FileInputStream(propertiesFile));
            } catch (IOException e) {
                System.err.println("Error loading from properties file " + propertiesFile.getAbsolutePath() + ": " + e.getMessage());
                return;
            }
            System.out.println("Reading properties file " + propertiesFile.getAbsolutePath());
            this.amqpDefinition.populateFromProperties(properties, "amqp", false, true);

            if (restInterface == null) {
                restInterface = properties.getProperty("rest.interface");
                System.out.println("    rest.interface = " + restInterface);
            }
            if (commands.isEmpty()) {
                String cmds = properties.getProperty("command", "");
                for (String command : cmds.split("\\s")) {
                    if (command != null && !command.trim().isEmpty()) {
                        commands.add(command.trim());
                    }
                }
                System.out.println("    commands = " + String.join(" ", commands));
            }
        }
    }

    protected void loadDefaults() {
        System.out.println("Loading defaults");

        this.amqpDefinition.populateFromDefaults(true, "amqp");

        if (restInterface == null) {
            restInterface = "http://127.0.0.1:5000";
            System.out.println("    rest.interface = " + restInterface);
        }
        if (commands.isEmpty()) {
            commands.add("sendtest");
            System.out.println("    commands = sendtest");
        }
    }

    protected MessageReceiver createMessageReceiver() throws IOException, TimeoutException {
        return new MessageReceiver(this.amqpDefinition, true);
    }

    protected MessageSender createMessageSender() throws IOException, TimeoutException {
        return new MessageSender(this.amqpDefinition);
    }


    public void run() {

        try {

			if (commands.size() == 0) {
                throw new IllegalArgumentException("No commands defined");
            }
            String command = commands.get(0);


            if (command.equalsIgnoreCase("listen")) {

            	System.out.println("Listening for messages from RabbitMQ service at " + this.amqpDefinition.getAmqpLocation() + ", queue name '" + this.amqpDefinition.getQueueName() + "'");
            	System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + restInterface);
            	MessageReceiver messageReceiver = this.createMessageReceiver();
            	try {
            	    messageReceiver.run(new RestMessageHandler(restInterface, objectTypes));
            	} catch (InterruptedException e) {
            	    e.printStackTrace();
            	}
            	messageReceiver.close();

			} else if (command.equalsIgnoreCase("send")) {
                System.out.println("Sending to "+this.amqpDefinition.getAmqpLocation()+", queue "+this.amqpDefinition.getQueueName());

                String operationName = commands.get(1);
                String objectTypeName = commands.get(2);
                MessageSender messageSender = this.createMessageSender();
                ObjectType objectType = objectTypes.get(objectTypeName);
                String authorization = null;
                Future<String> response = null;
                try {
                    if (operationName.equalsIgnoreCase("create")) {
                        response = messageSender.send(objectType, "create", null, getJSONObjectFromFilename(commands.get(3)), authorization);
                    } else if (operationName.equalsIgnoreCase("update")) {
                        response = messageSender.send(objectType, "update", UUID.fromString(commands.get(3)), getJSONObjectFromFilename(commands.get(4)), authorization);
                    } else if (operationName.equalsIgnoreCase("passivate")) {
                        response = messageSender.send(objectType, "passivate", UUID.fromString(commands.get(3)), objectType.getPassivateObject(commands.get(4)), authorization);
                    } else if (operationName.equalsIgnoreCase("delete")) {
                        response = messageSender.send(objectType, "delete", UUID.fromString(commands.get(3)), objectType.getDeleteObject(commands.get(4)), authorization);
                    }
                    if (response != null) {
                        System.out.println(response.get());
                    }

                } catch (JSONException e) {
                    e.printStackTrace();
                } catch (OperationNotSupportedException e) {
                    e.printStackTrace();
                } catch (IndexOutOfBoundsException e) {
                    throw new IllegalArgumentException("Incorrect number of arguments; the '" + command + "' command takes more arguments");
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } catch (ExecutionException e) {
                    e.printStackTrace();
                }
                messageSender.close();
            }
        } catch (MalformedURLException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        }
        System.exit(0);
    }

    private static JSONObject getJSONObjectFromFilename(String jsonFilename) throws FileNotFoundException, JSONException {
        return new JSONObject(new JSONTokener(new FileReader(new File(jsonFilename))));
    }
}
