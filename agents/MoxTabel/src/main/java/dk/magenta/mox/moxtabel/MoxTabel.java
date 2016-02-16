package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.AmqpDefinition;
import dk.magenta.mox.agent.MessageReceiver;
import dk.magenta.mox.agent.MessageSender;
import dk.magenta.mox.agent.MoxAgent;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;

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

        this.listenerDefinition = new AmqpDefinition();
        this.listenerDefinition.populateFromMap(this.commandLineArgs, listenerPrefix, true, true);
        this.listenerDefinition.populateFromProperties(this.properties, listenerPrefix, false);
        this.listenerDefinition.populateFromDefaults(true, listenerPrefix);

        this.senderDefinition = new AmqpDefinition();
        this.senderDefinition.populateFromMap(this.commandLineArgs, senderPrefix, true, true);
        this.senderDefinition.populateFromProperties(this.properties, senderPrefix, false);
        this.senderDefinition.populateFromDefaults(true, senderPrefix);
    }

    protected String getDefaultPropertiesFileName() {
        return "moxtabel.properties";
    }

    @Override
    public void run() {
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
