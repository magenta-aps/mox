package dk.magenta.mox.agent;

import com.rabbitmq.client.ConnectionFactory;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.QueueingConsumer;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.concurrent.TimeoutException;

public class MessageReceiver {

    private Connection connection;
    private Channel channel;
    private String queue;
    private QueueingConsumer consumer;

    public MessageReceiver(String host, String queue) throws IOException, TimeoutException {
        if (!connectionFactories.keySet().contains(host)) {
            ConnectionFactory factory = new ConnectionFactory();
            int port = 5672;
            if (host.contains(":")) {
                int index = host.indexOf(":");
                port = Integer.parseInt(host.substring(index+1));
                host = host.substring(0, index);
            }
            factory.setHost(host);
            factory.setPort(port);
            connectionFactories.put(host, factory);
        }
        this.connection = connectionFactories.get(host).newConnection();
        this.channel = connection.createChannel();
        this.channel.queueDeclare(queue, false, false, false, null);
        /*if (exchange == null) {
            exchange = "";
        }
        this.exchange = exchange;*/
        this.queue = queue;

        this.consumer = new QueueingConsumer(this.channel);
        this.channel.basicConsume(queue, true, this.consumer);

    }

    private static HashMap<String, ConnectionFactory> connectionFactories = new HashMap<String, ConnectionFactory>();

    public void run(MessageReceivedCallback callback) throws InterruptedException {
        while (true) {
            QueueingConsumer.Delivery delivery = this.consumer.nextDelivery();
            try {
                callback.run(delivery.getProperties().getHeaders(), new JSONObject(new String(delivery.getBody())));
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }


    public void close() {
        if (this.channel != null) {
            try {
                this.channel.close();
            } catch (IOException e) {
                e.printStackTrace();
            } catch (TimeoutException e) {
                e.printStackTrace();
            }
        }
        if (this.connection != null) {
            try {
                this.connection.close();
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }
}
