package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import dk.magenta.mox.agent.MoxAgent;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.IOException;
import java.io.FileInputStream;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.TimeoutException;

public class MoxRestFrontend extends MoxAgent {

    private String restInterface = null;

    private Map<String, ObjectType> objectTypeMap;

    private Logger log = Logger.getLogger(MoxRestFrontend.class);

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxRestFrontend agent;
        try {
            agent = new MoxRestFrontend(args);
        } catch (Exception e) {
            return;
        }
        agent.run();
    }

    public MoxRestFrontend(String[] args) throws IOException {
        super(args);
        this.restInterface = this.getSetting("moxrestfrontend.rest.host");

        try {
            Properties objectTypeConfig = new Properties();
            objectTypeConfig.load(new FileInputStream("structure.conf"));
            this.objectTypeMap = ObjectType.load(objectTypeConfig);
        } catch (IOException e) {
            this.log.error("Error loading from properties file structure.conf: " + e.getMessage());
            System.err.println("Failed loading structure.conf");
            throw e;
        }

        Runtime.getRuntime().addShutdownHook(new Thread() {
            public void run() {
                MoxRestFrontend.this.shutdown();
            }
        });
    }

    protected String getDefaultPropertiesFileName() {
        return "moxrestfrontend.conf";
    }

    protected String getAmqpPrefix() {
        return "moxrestfrontend.amqp";
    }

    public void run() {
        log.info("\n--------------------------------------------------------------------------------");
        log.info("MoxRestFrontend Starting");
        AmqpDefinition amqpDefinition = this.getAmqpDefinition();
        MessageReceiver messageReceiver = null;
        try {
            log.info("Creating MessageReceiver instance");
            messageReceiver = this.createMessageReceiver();
            messageReceiver.setThrottleSize(20);
            log.info("Running MessageReceiver instance");
            log.info("Listening for messages from RabbitMQ service at " + amqpDefinition.getHost() + ", exchange '" + amqpDefinition.getExchange() + "' (bound to queue '"+messageReceiver.getQueue()+"')");
            log.info("Successfully parsed messages will be forwarded to the REST interface at " + this.restInterface);
            messageReceiver.run(new RestMessageHandler(this.restInterface, this.objectTypeMap));
            log.info("MessageReceiver instance stopped on its own");
        } catch (InterruptedException | IOException | TimeoutException e) {
            e.printStackTrace();
        }
        log.info("MoxRestFrontend Shutting down");
        if (messageReceiver != null) {
            messageReceiver.close();
        }
        log.info("--------------------------------------------------------------------------------\n");
    }

    protected void shutdown() {
        this.log.info("Received SIGINT");
        this.log.info("MoxRestFrontend shutting down");
        log.info("--------------------------------------------------------------------------------\n");
    }
}