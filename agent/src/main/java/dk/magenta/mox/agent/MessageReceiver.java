package dk.magenta.mox.agent;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.QueueingConsumer;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.logging.Logger;

public class MessageReceiver extends MessageInterface {

    private QueueingConsumer consumer;
    private boolean running;
    private boolean sendReplies;

    public MessageReceiver(String host, String exchange, String queue, boolean sendReplies) throws IOException, TimeoutException {
        this(null, null, host, exchange, queue, sendReplies);
    }
    public MessageReceiver(String username, String password, String host, String exchange, String queue, boolean sendReplies) throws IOException, TimeoutException {
        super(username, password, host, exchange, queue);
        this.consumer = new QueueingConsumer(this.getChannel());
        this.getChannel().basicConsume(queue, true, this.consumer);
        this.sendReplies = sendReplies;
    }

    public void run(MessageHandler callback) throws InterruptedException {
        this.running = true;
        while (this.running) {
            QueueingConsumer.Delivery delivery = this.consumer.nextDelivery();
            System.out.println("----------------------------");
            System.out.println("Got a message from the queue");
            System.out.println("Properties: "+delivery.getProperties());
            this.logger.info("----------------------------");
            this.logger.info("Got a message from the queue");
            this.logger.info("Properties: " + delivery.getProperties());

            final AMQP.BasicProperties deliveryProperties = delivery.getProperties();
            final AMQP.BasicProperties responseProperties = new AMQP.BasicProperties().builder().correlationId(deliveryProperties.getCorrelationId()).build();
            final String replyTo = deliveryProperties.getReplyTo();
            System.out.println("Send response to (replyTo:"+deliveryProperties.getReplyTo()+", correlationId:"+deliveryProperties.getCorrelationId()+")");
            this.logger.info("Send response to (replyTo:"+deliveryProperties.getReplyTo()+", correlationId:"+deliveryProperties.getCorrelationId()+")");

            String data = new String(delivery.getBody()).trim();
            JSONObject dataObject;
            try {
                dataObject = new JSONObject(data.isEmpty() ? "{}" : data);
            } catch (JSONException e) {
                try {
                    MessageReceiver.this.getChannel().basicPublish("", replyTo, responseProperties, Util.error(e).getBytes());
                } catch (IOException e1) {
                    e1.printStackTrace();
                }
                continue;
            }
            final Future<String> response = callback.run(delivery.getProperties().getHeaders(), dataObject);

            if (this.sendReplies && response != null) {

                // Wait for a response from the callback and send it back to the original message sender
                new Thread(new Runnable() {
                    public void run() {
                        try {
                            String responseString = response.get(30, TimeUnit.SECONDS); // This blocks while we wait for the callback to run. Hence the thread
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



    public void stop() {
        this.running = false;
    }
}
