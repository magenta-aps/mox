package dk.magenta.mox.agent;

import org.apache.log4j.Logger;

import java.util.Map;
import java.util.Properties;

/**
 * Created by lars on 25-01-16.
 */
public class AmqpDefinition {
    private String username;
    private String password;
    private String host;
    private String exchange;
    private String queue;
    private Logger log = Logger.getLogger(AmqpDefinition.class);

    public AmqpDefinition() {

    }

    public AmqpDefinition(String username, String password, String host, String exchange, String queue) {
        this.username = username;
        this.password = password;
        this.host = host;
        this.exchange = exchange;
        this.queue = queue;
    }

    public AmqpDefinition(ParameterMap<String, String> commandLineArgs, Properties properties, String prefix) {
        this(commandLineArgs, properties, prefix, true);
    }
    public AmqpDefinition(ParameterMap<String, String> commandLineArgs, Properties properties, String prefix, boolean print) {
        this();
        this.populateFromMap(commandLineArgs, prefix, true, print);
        this.populateFromProperties(properties, prefix, false, print);
        this.populateFromDefaults(print, prefix);
    }

    public boolean complete() {
        return (this.username != null && this.password != null && this.host != null && this.queue != null);
    }

    //--------------------------------------------------------------------------

    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public String getHost() {
        return host;
    }

    public String getExchange() {
        return exchange;
    }

    public String getQueue() {
        return queue;
    }

    //--------------------------------------------------------------------------

    public void setUsername(String username) {
        this.username = username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setHost(String host) {
        this.host = host;
    }

    public void setExchange(String exchange) {
        this.exchange = this.exchange;
    }

    public void setQueue(String queue) {
        this.queue = queue;
    }

    //--------------------------------------------------------------------------

    public boolean populateFromProperties(Properties properties, String prefix, boolean overwrite) {
        return populateFromProperties(properties, prefix, overwrite, false);
    }
    public boolean populateFromProperties(Properties properties, String prefix, boolean overwrite, boolean print) {
        return this.populateFromProperties(properties, prefix, overwrite, print, 4);
    }

    public boolean populateFromProperties(Properties properties, String prefix, boolean overwrite, boolean print, int printIndent) {
        boolean changed = false;
        if (properties != null) {
            if (overwrite || this.username == null) {
                String username = this.getFromProperties(properties, prefix + ".username", print, printIndent, false);
                if (username != null) {
                    this.username = username;
                    changed = true;
                }
            }
            if (overwrite || this.password == null) {
                String password = this.getFromProperties(properties, prefix + ".password", print, printIndent, true);
                if (password != null) {
                    this.password = password;
                    changed = true;
                }
            }
            if (overwrite || this.host == null) {
                String location = this.getFromProperties(properties, prefix + ".host", print, printIndent, true);
                if (location != null) {
                    this.host = location;
                    changed = true;
                }
            }
            if (overwrite || this.exchange == null) {
                String exchange = this.getFromProperties(properties, prefix + ".exchange", print, printIndent, true);
                if (exchange != null) {
                    this.exchange = exchange;
                    changed = true;
                }
            }
            if (overwrite || this.queue == null) {
                String queue = this.getFromProperties(properties, prefix + ".queue", print, printIndent, true);
                if (queue != null) {
                    this.queue = queue;
                    changed = true;
                }
            }
        }
        return changed;
    }

    private String getFromProperties(Properties properties, String key, boolean print, int printIndent, boolean secret) {
        String value = properties.getProperty(key);
        if (value != null) {
            if (print) {
                this.log.info(this.repeat(printIndent, ' ') + key + " = " + (secret ? "****" : value));
            }
        }
        return value;
    }

    //--------------------------------------------------------------------------

    public boolean populateFromDefaults(boolean print, String prefix) {
        return this.populateFromDefaults(print, prefix, 4);
    }

    public boolean populateFromDefaults(boolean print, String prefix, int printIndent) {
        boolean changed = false;
        if (this.host == null) {
            this.host = "localhost:5672";
            this.log.info(this.formatValue("host", this.host, printIndent, prefix));
            changed = true;
        }
        return changed;
    }

    //--------------------------------------------------------------------------
    public boolean populateFromMap(Map<String, String> map, String prefix, boolean overwrite, boolean print) {
        return this.populateFromMap(map, prefix, overwrite, print, 4);
    }
    public boolean populateFromMap(Map<String, String> map, String prefix, boolean overwrite, boolean print, int printIndent) {
        boolean changed = false;
        if (map != null) {
            if (overwrite || this.username == null) {
                String username = this.getFromMap(map, prefix + ".username", print, printIndent, false);
                if (username != null) {
                    this.username = username;
                    changed = true;
                }
            }
            if (overwrite || this.password == null) {
                String password = this.getFromMap(map, prefix + ".password", print, printIndent, true);
                if (password != null) {
                    this.password = password;
                    changed = true;
                }
            }
            if (overwrite || this.host == null) {
                String amqpLocation = this.getFromMap(map, prefix + ".host", print, printIndent, false);
                if (amqpLocation != null) {
                    this.host = amqpLocation;
                    changed = true;
                }
            }
            if (overwrite || this.exchange == null) {
                String exchangeName = this.getFromMap(map, prefix + ".exchange", print, printIndent, false);
                if (exchangeName != null) {
                    this.exchange = exchangeName;
                    changed = true;
                }
            }
            if (overwrite || this.queue == null) {
                String queueName = this.getFromMap(map, prefix + ".queue", print, printIndent, false);
                if (queueName != null) {
                    this.queue = queueName;
                    changed = true;
                }
            }
        }
        return changed;
    }

    private String getFromMap(Map<String, String> map, String key, boolean print, int printIndent, boolean secret) {
        String value = map.get(key);
        if (value != null) {
            if (print) {
                this.log.info(this.repeat(printIndent, ' ') + key + " = " + (secret ? "****" : value));
            }
        }
        return value;
    }

    public boolean populateFromMap(ParameterMap<String, String> map, String prefix, boolean overwrite, boolean print) {
        return this.populateFromMap(map.getFirstMap(), prefix, overwrite, print);
    }
    public boolean populateFromMap(ParameterMap<String, String> map, String prefix, boolean overwrite, boolean print, int printIndent) {
        return this.populateFromMap(map.getFirstMap(), prefix, overwrite, print, printIndent);
    }

    //--------------------------------------------------------------------------

    private String formatValue(String key, String value, int printIndent, String prefix) {
       return this.repeat(printIndent, ' ') + prefix + "." + key + " = " + value;
    }

    private String repeat(int count, char ch) {
        if (count > 0) {
            return String.format("%0" + count + "d", 0).replace('0', ch);
        } else {
            return "";
        }
    }
}
