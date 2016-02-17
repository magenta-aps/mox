package dk.magenta.mox.moxrestfrontend;

import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import dk.magenta.mox.agent.MoxAgent;
import org.apache.log4j.xml.DOMConfigurator;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.TimeoutException;

public class MoxRestFrontend extends MoxAgent {

    private String restInterface = null;

    private Map<String, ObjectType> objectTypeMap;

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
        AmqpDefinition amqpDefinition = this.getAmqpDefinition();
        System.out.println("Listening for messages from RabbitMQ service at " + amqpDefinition + ", queue name '" + amqpDefinition + "'");
        System.out.println("Successfully parsed messages will be forwarded to the REST interface at " + this.restInterface);
        MessageReceiver messageReceiver = null;
        try {
            messageReceiver = this.createMessageReceiver();
            messageReceiver.run(new RestMessageHandler(this.restInterface, this.objectTypeMap));
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (TimeoutException e) {
            e.printStackTrace();
        }
        if (messageReceiver != null) {
            messageReceiver.close();
        }
    }
}