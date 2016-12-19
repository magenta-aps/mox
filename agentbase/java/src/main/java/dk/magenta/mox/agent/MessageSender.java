package dk.magenta.mox.agent;


import com.rabbitmq.client.AMQP;

import java.io.IOException;
import java.util.*;
import java.util.concurrent.*;

import com.rabbitmq.client.QueueingConsumer;
import dk.magenta.mox.agent.messages.Message;


public class MessageSender extends MessageInterface {

    private String appId;
    private String clusterId;
    private String replyQueue;
    private QueueingConsumer replyConsumer;
    private HashMap<String, SettableFuture<String>> responseExpectors = new HashMap<String, SettableFuture<String>>();
    private boolean listening = false;

    public MessageSender(AmqpDefinition amqpDefinition) throws IOException {
        super(amqpDefinition);
        this.setup();
    }

    private void setup() throws IOException {
        this.getChannel().exchangeDeclare(this.getExchange(), "fanout", true);

        this.replyQueue = this.getChannel().queueDeclare().getQueue();
        this.replyConsumer = new QueueingConsumer(this.getChannel());
        this.getChannel().basicConsume(this.replyQueue, true, this.replyConsumer);
    }

    public String getAppId() {
        return appId;
    }

    public void setAppId(String appId) {
        this.appId = appId;
    }

    public String getClusterId() {
        return clusterId;
    }

    public void setClusterId(String clusterId) {
        this.clusterId = clusterId;
    }

    public AMQP.BasicProperties.Builder getStandardPropertyBuilder() {
        AMQP.BasicProperties.Builder propertyBuilder = new AMQP.BasicProperties.Builder();
        if (this.appId != null) {
            propertyBuilder = propertyBuilder.appId(this.appId);
        }
        if (this.clusterId != null) {
            propertyBuilder = propertyBuilder.clusterId(this.clusterId);
        }
        if (this.replyQueue != null) {
            propertyBuilder = propertyBuilder.replyTo(this.replyQueue);
        }

        propertyBuilder = propertyBuilder.messageId(UUID.randomUUID().toString()).timestamp(new Date());

        return propertyBuilder;
    }

    public Future<String> send(Message message) throws IOException, InterruptedException {
        return this.send(message, true);
    }

    public Future<String> send(Message message, boolean expectReply) throws IOException, InterruptedException {
        this.log.info("Sending message: \n"+message.getHeaders()+"\n"+message.getJSON().toString());

        String correlationId = UUID.randomUUID().toString();
        AMQP.BasicProperties properties = this.getStandardPropertyBuilder().headers(message.getHeaders()).contentType("application/json").correlationId(correlationId).build();

        this.getChannel().basicPublish(this.getExchange(), "", properties, message.getJSON().toString().getBytes());

        if (expectReply) {
            SettableFuture<String> expector = new SettableFuture<String>(); // Set up a Future<> to wait for a reply
            this.responseExpectors.put(correlationId, expector);
            this.startListening();
            return expector;
        } else {
            return new ImmediateFuture<String>("");
        }
    }

    private void startListening() {
        // The replyConsumer lets us receive replies one at a time, but we have no guarantee that the next incoming reply matches our latest send
        // Therefore we listen for ALL such replies, and match them with our expecting SettableFutures. When a reply comes in, it gets applied to the matching SettableFuture
        // which then completes and gets removed. Wherever get() call that Future was blocking will resume execution
        if (!this.listening) {
            new Thread(new Runnable() {
                public void run() {
                    while (MessageSender.this.responseExpectors.size() > 0) {
                        MessageSender.this.listening = true;
                        try {
                            QueueingConsumer.Delivery delivery = MessageSender.this.replyConsumer.nextDelivery();
                            String expectorId = delivery.getProperties().getCorrelationId();
                            if (expectorId != null) {
                                SettableFuture<String> expector = MessageSender.this.responseExpectors.get(expectorId);
                                if (expector != null) {
                                    expector.set(new String(delivery.getBody()));
                                    MessageSender.this.responseExpectors.remove(expectorId);
                                }
                            }
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                            MessageSender.this.log.error(e);
                        }
                    }
                    MessageSender.this.listening = false;
                }
            }).start();
        }
    }

}
