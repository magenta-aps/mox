package dk.magenta.moxagent;


import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;

import java.io.IOException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeoutException;

import org.json.*;


public class MessageSender {

    private Connection connection;
    private Channel channel;
    private String exchange;
    private String queue;
    private String appId;
    private String clusterId;

    public MessageSender(String host, String exchange, String queue) throws IOException, TimeoutException {
        if (!connectionFactories.keySet().contains(host)) {
            ConnectionFactory factory = new ConnectionFactory();
            factory.setHost(host);
            factory.setPort(5672);
            connectionFactories.put(host, factory);
        }
        this.connection = connectionFactories.get(host).newConnection();
        this.channel = connection.createChannel();
        this.channel.queueDeclare(queue, false, false, false, null);
        if (exchange == null) {
            exchange = "";
        }
        this.exchange = exchange;
        this.queue = queue;
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


    private static HashMap<String, ConnectionFactory> connectionFactories = new HashMap<String, ConnectionFactory>();


    public AMQP.BasicProperties.Builder getStandardPropertyBuilder() {
        AMQP.BasicProperties.Builder propertyBuilder = new AMQP.BasicProperties.Builder();
        if (this.appId != null) {
            propertyBuilder = propertyBuilder.appId(this.appId);
        }
        if (this.clusterId != null) {
            propertyBuilder = propertyBuilder.clusterId(this.clusterId);
        }
        propertyBuilder = propertyBuilder.messageId(UUID.randomUUID().toString()).timestamp(new Date());

        return propertyBuilder;
    }


    public void sendJSON(Map<String, Object> headers, JSONObject jsonObject) throws IOException {
        if (headers == null) {
            headers = new HashMap<String, Object>();
        }
        AMQP.BasicProperties properties = this.getStandardPropertyBuilder().headers(headers).contentType("application/json").build();
        this.send(properties, jsonObject.toString().getBytes());
    }


    public void send(AMQP.BasicProperties properties, byte[] payload) throws IOException {
        this.channel.basicPublish(this.exchange, this.queue, properties, payload);
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
