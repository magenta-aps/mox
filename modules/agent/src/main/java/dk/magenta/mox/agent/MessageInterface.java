package dk.magenta.mox.agent;

import com.rabbitmq.client.AMQP;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.ConnectionFactory;
import org.apache.log4j.Logger;

import java.io.IOException;
import java.util.HashMap;
import java.util.UUID;

/**
 * Created by lars on 03-08-15.
 */
public abstract class MessageInterface {

    private String id;
    private Connection connection;
    private Channel channel;
    private String exchange;
    private String queueName;
    private AMQP.Queue.DeclareOk queueResult;
    protected Logger log = Logger.getLogger(this.getClass());


    private static HashMap<String, ConnectionFactory> connectionFactories = new HashMap<String, ConnectionFactory>();

    public MessageInterface(AmqpDefinition amqpDefinition) throws IOException {
        this(amqpDefinition.getUsername(),
                amqpDefinition.getPassword(),
                amqpDefinition.getAmqpLocation(),
                amqpDefinition.getExchangeName(),
                amqpDefinition.getQueueName());
    }

    public MessageInterface(String host, String exchange, String queueName) throws IOException {
        this(null, null, host, exchange, queueName);
    }
    public MessageInterface(String username, String password, String host, String exchange, String queueName) throws IOException {
        if (username == null) {
            username = ConnectionFactory.DEFAULT_USER;
        }
        if (password == null) {
            password = ConnectionFactory.DEFAULT_PASS;
        }

        this.id = UUID.randomUUID().toString();
        if (!connectionFactories.keySet().contains(host)) {
            ConnectionFactory factory = new ConnectionFactory();
            int port = 5672;
            if (host.contains(":")) {
                int index = host.indexOf(":");
                port = Integer.parseInt(host.substring(index + 1));
                host = host.substring(0, index);
            }
            factory.setHost(host);
            factory.setPort(port);
            factory.setUsername(username);
            factory.setPassword(password);
            connectionFactories.put(host, factory);
        }
        if (exchange == null) {
            exchange = "";
        }
        this.exchange = exchange;
        this.queueName = queueName;
        this.connection = connectionFactories.get(host).newConnection();
        this.channel = connection.createChannel();
        this.queueResult = this.channel.queueDeclare(queueName, false, false, false, null);
    }

    public String getId() {
        return id;
    }

    public Connection getConnection() {
        return connection;
    }

    public Channel getChannel() {
        return channel;
    }

    public String getHost() {
        return this.connection.getAddress().getHostName();
    }

    public String getExchange() {
        return exchange;
    }

    public String getQueueName() {
        return queueName;
    }

    public AMQP.Queue.DeclareOk getQueueResult() {
        return queueResult;
    }

    public void close() {
        if (this.channel != null) {
            try {
                this.channel.close();
            } catch (IOException e) {
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
