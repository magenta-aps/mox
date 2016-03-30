package dk.magenta.mox.agent;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.QueueingConsumer;
import dk.magenta.mox.agent.messages.Headers;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

public class MessageReceiver extends MessageInterface {

    private QueueingConsumer consumer;
    private boolean running;
    private boolean sendReplies;

    public MessageReceiver(AmqpDefinition amqpDefinition) throws IOException {
        super(amqpDefinition);
        this.setupConsumer();
    }
    public MessageReceiver(AmqpDefinition amqpDefinition, boolean sendReplies) throws IOException {
        super(amqpDefinition);
        this.sendReplies = sendReplies;
        this.setupConsumer();
    }

    public MessageReceiver(String host, String exchange, String queue, boolean sendReplies) throws IOException, TimeoutException {
        this(null, null, host, exchange, queue, sendReplies);
    }
    public MessageReceiver(String username, String password, String host, String exchange, String queue, boolean sendReplies) throws IOException, TimeoutException {
        super(username, password, host, exchange, queue);
        this.setupConsumer();
    }

    private void setupConsumer() throws IOException {
        this.consumer = new QueueingConsumer(this.getChannel());
        if (consumer == null) {
            throw new IOException("Couldn't open listener");
        }
        this.getChannel().basicConsume(this.getQueueName(), true, this.consumer);
    }

    public void run(MessageHandler callback) throws InterruptedException {
        this.running = true;
        while (this.running) {
            QueueingConsumer.Delivery delivery = this.consumer.nextDelivery();
            this.log.info("--------------------------------------------------------------------------------");
            this.log.info("Got a message from the queue");

            final AMQP.BasicProperties deliveryProperties = delivery.getProperties();
            final AMQP.BasicProperties responseProperties = new AMQP.BasicProperties().builder().correlationId(deliveryProperties.getCorrelationId()).build();
            final String replyTo = deliveryProperties.getReplyTo();

            this.log.info("ReplyTo: " + deliveryProperties.getReplyTo());
            this.log.info("CorrelationId: " + deliveryProperties.getCorrelationId());
            this.log.info("MessageId: " + deliveryProperties.getMessageId());
            this.log.info("Headers: " + deliveryProperties.getHeaders());
            String data = "";
            try {
                data = new String(delivery.getBody(), "utf-8").trim();
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            this.log.info("Data: "+data);

            JSONObject dataObject;
            try {
                dataObject = new JSONObject(data.isEmpty() ? "{}" : data);
            } catch (JSONException e) {
                this.log.info("Message body could not be parsed as JSON.\nReturning error message back to sender.");
                try {
                    MessageReceiver.this.getChannel().basicPublish("", replyTo, responseProperties, Util.error(e).getBytes());
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
                continue;
            }
            final Future<String> response = callback.run(new Headers(delivery.getProperties().getHeaders()), dataObject);

            if (this.sendReplies) {
                if (response == null) {
                    try {
                        this.log.info("Handler returned nothing. Informing sender.");
                        this.getChannel().basicPublish("", replyTo, responseProperties, "No response".getBytes());
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                } else {
                    // Wait for a response from the callback and send it back to the original message sender
                    new Thread(new Runnable() {
                        public void run() {
                            String responseString;
                            try {
                                responseString = response.get(30, TimeUnit.SECONDS); // This blocks while we wait for the callback to run. Hence the thread
                            } catch (InterruptedException | ExecutionException | TimeoutException e) {
                                e.printStackTrace();
                                responseString = Util.error(e);
                            }
                            MessageReceiver.this.log.info("Got a response from message handler. Relaying to sender.");
                            MessageReceiver.this.log.info(responseString);
                            try {
                                MessageReceiver.this.getChannel().basicPublish("", replyTo, responseProperties, responseString.getBytes());
                            } catch (Exception e) {
                                try {
                                    MessageReceiver.this.getChannel().basicPublish("", replyTo, responseProperties, Util.error(e).getBytes());
                                } catch (IOException e1) {
                                    e1.printStackTrace();
                                }
                            }
                        }
                    }).start();
                }
            }
        }
    }



    public void stop() {
        this.running = false;
    }
}
