package dk.magenta.mox.agent;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.QueueingConsumer;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeoutException;

public class MessageReceiver extends MessageInterface {

    private QueueingConsumer consumer;

    public MessageReceiver(String host, String exchange, String queue) throws IOException, TimeoutException {
        super(host, exchange, queue);
        this.consumer = new QueueingConsumer(this.getChannel());
        this.getChannel().basicConsume(queue, true, this.consumer);
    }

    public void run(MessageReceivedCallback callback) throws InterruptedException {
        while (true) {
            QueueingConsumer.Delivery delivery = this.consumer.nextDelivery();

            final AMQP.BasicProperties deliveryProperties = delivery.getProperties();
            final AMQP.BasicProperties responseProperties = new AMQP.BasicProperties().builder().correlationId(deliveryProperties.getCorrelationId()).build();

            try {
                final Future<String> response = callback.run(delivery.getProperties().getHeaders(), new JSONObject(new String(delivery.getBody())));

                // Wait for a response from the callback and send it back to the original message sender
                new Thread(new Runnable() {
                    public void run() {
                        try {
                            String responseString = response.get(); // This blocks while we wait for the callback to run. Hence the thread
                            MessageReceiver.this.getChannel().basicPublish("", deliveryProperties.getReplyTo(), responseProperties, responseString.getBytes());
                        } catch (InterruptedException e) {
                            e.printStackTrace();
                        } catch (ExecutionException e) {
                            e.printStackTrace();
                        } catch (IOException e) {
                            e.printStackTrace();
                        }
                    }
                }).start();

            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }
}
