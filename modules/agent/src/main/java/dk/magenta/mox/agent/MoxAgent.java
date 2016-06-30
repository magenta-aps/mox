package dk.magenta.mox.agent;

import java.io.*;
import java.util.ArrayList;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 06-08-15.
 */
public class MoxAgent extends MoxAgentBase {

    private AmqpDefinition amqpDefinition;

    public AmqpDefinition getAmqpDefinition() {
        return amqpDefinition;
    }

    private ArrayList<MessageReceiver> messageReceivers = new ArrayList<>();
    private ArrayList<MessageSender> messageSenders = new ArrayList<>();

    protected MoxAgent() {
        this.loadDefaults();
        try {
            this.loadProperties();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.amqpDefinition = new AmqpDefinition(this.commandLineArgs, this.properties, this.getAmqpPrefix(), true);
    }

    public MoxAgent(String[] args) {

        this.loadDefaults();
        this.loadArgs(args);
        try {
            this.loadProperties();
        } catch (IOException e) {
            e.printStackTrace();
        }

        this.amqpDefinition = new AmqpDefinition(this.commandLineArgs, this.properties, this.getAmqpPrefix(), true);
    }

    protected String getAmqpPrefix() {
        return "amqp";
    }
    
    protected MessageReceiver createMessageReceiver(AmqpDefinition amqpDefinition) throws IOException, TimeoutException {
        MessageReceiver receiver = new MessageReceiver(amqpDefinition, true);
        this.messageReceivers.add(receiver);
        return receiver;
    }

    protected MessageSender createMessageSender(AmqpDefinition amqpDefinition) throws IOException, TimeoutException {
        MessageSender sender = new MessageSender(amqpDefinition);
        this.messageSenders.add(sender);
        return sender;
    }

    protected MessageReceiver createMessageReceiver() throws IOException, TimeoutException {
        return this.createMessageReceiver(this.amqpDefinition);
    }
    protected MessageSender createMessageSender() throws IOException, TimeoutException {
        return this.createMessageSender(this.amqpDefinition);
    }


    public void run() {
    }

    protected void shutdown() {
        this.cleanup();
    }

    protected void cleanup() {
        for (MessageReceiver receiver : this.messageReceivers) {
            receiver.stop();
            receiver.close();
        }
        for (MessageSender sender : this.messageSenders) {
            sender.close();
        }
    }
}
