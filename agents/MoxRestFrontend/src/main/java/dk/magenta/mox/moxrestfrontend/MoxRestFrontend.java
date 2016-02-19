package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import dk.magenta.mox.agent.MoxAgent;
import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.TimeoutException;

public class MoxRestFrontend extends MoxAgent {

    private String restInterface = null;

    private Map<String, ObjectType> objectTypeMap;

    private Logger log = Logger.getLogger(MoxRestFrontend.class);

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
        MoxRestFrontend agent = new MoxRestFrontend(args);
        agent.run();
    }

    public MoxRestFrontend(String[] args) {
        super(args);
        this.restInterface = this.getSetting("rest.interface");
        this.objectTypeMap = ObjectType.load(this.properties);
    }

    public void run() {
        log.info("\n--------------------------------------------------------------------------------");
        log.info("MoxRestFrontend Starting");
        AmqpDefinition amqpDefinition = this.getAmqpDefinition();
        log.info("Listening for messages from RabbitMQ service at " + amqpDefinition.getAmqpLocation() + ", queue name '" + amqpDefinition.getQueueName() + "'");
        log.info("Successfully parsed messages will be forwarded to the REST interface at " + this.restInterface);
        MessageReceiver messageReceiver = null;
        try {
            log.info("Creating MessageReceiver instance");
            messageReceiver = this.createMessageReceiver();
            log.info("Running MessageReceiver instance");
            messageReceiver.run(new RestMessageHandler(this.restInterface, this.objectTypeMap));
            log.info("MessageReceiver instance stopped on its own");
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        }
        log.info("MoxRestFrontend Shutting down");
        if (messageReceiver != null) {
            messageReceiver.close();
        }
        log.info("--------------------------------------------------------------------------------\n");
    }
}