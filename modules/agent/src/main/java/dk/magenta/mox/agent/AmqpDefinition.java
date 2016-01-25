package dk.magenta.mox.agent;

import java.util.Map;
import java.util.Properties;

/**
 * Created by lars on 25-01-16.
 */
public class AmqpDefinition {
    private String username;
    private String password;
    private String amqpLocation;
    private String exchangeName;
    private String queueName;

    public AmqpDefinition() {

    }

    public AmqpDefinition(String username, String password, String amqpLocation, String exchangeName, String queueName) {
        this.username = username;
        this.password = password;
        this.amqpLocation = amqpLocation;
        this.exchangeName = exchangeName;
        this.queueName = queueName;
    }

    public boolean complete() {
        return (this.username != null && this.password != null && this.amqpLocation != null && this.queueName != null);
    }

    //--------------------------------------------------------------------------

    public String getUsername() {
        return username;
    }

    public String getPassword() {
        return password;
    }

    public String getAmqpLocation() {
        return amqpLocation;
    }

    public String getExchangeName() {
        return exchangeName;
    }

    public String getQueueName() {
        return queueName;
    }

    //--------------------------------------------------------------------------

    public void setUsername(String username) {
        this.username = username;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public void setAmqpLocation(String amqpLocation) {
        this.amqpLocation = amqpLocation;
    }

    public void setExchangeName(String exchangeName) {
        this.exchangeName = exchangeName;
    }

    public void setQueueName(String queueName) {
        this.queueName = queueName;
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
        if (overwrite || this.amqpLocation == null) {
            String location = this.getFromProperties(properties, prefix + ".amqpLocation", print, printIndent, true);
            if (location != null) {
                this.amqpLocation = location;
                changed = true;
            }
        }
        if (overwrite || this.exchangeName == null) {
            String exchange = this.getFromProperties(properties, prefix + ".exchangeName", print, printIndent, true);
            if (exchange != null) {
                this.exchangeName = exchange;
                changed = true;
            }
        }
        if (overwrite || this.queueName == null) {
            String queue = this.getFromProperties(properties, prefix + ".queueName", print, printIndent, true);
            if (queue != null) {
                this.queueName = queue;
                changed = true;
            }
        }
        return changed;
    }

    private String getFromProperties(Properties properties, String key, boolean print, int printIndent, boolean secret) {
        String value = properties.getProperty(key);
        if (value != null) {
            if (print) {
                System.out.println(this.repeat(printIndent, ' ') + key + " = " + (secret ? "****" : value));
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
        if (this.amqpLocation == null) {
            this.amqpLocation = "localhost:5672";
            System.out.println(this.formatValue("amqpLocation", this.amqpLocation, printIndent, prefix));
            changed = true;
        }
        if (this.queueName == null) {
            this.queueName = "incoming";
            System.out.println(this.formatValue("queueName", this.queueName, printIndent, prefix));
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
        if (overwrite || this.amqpLocation == null) {
            String amqpLocation = this.getFromMap(map, prefix + ".amqpLocation", print, printIndent, false);
            if (amqpLocation != null) {
                this.amqpLocation = amqpLocation;
                changed = true;
            }
        }
        if (overwrite || this.exchangeName == null) {
            String exchangeName = this.getFromMap(map, prefix + ".exchangeName", print, printIndent, false);
            if (exchangeName != null) {
                this.exchangeName = exchangeName;
                changed = true;
            }
        }
        if (overwrite || this.queueName == null) {
            String queueName = this.getFromMap(map, prefix + ".queueName", print, printIndent, false);
            if (queueName != null) {
                this.queueName = queueName;
                changed = true;
            }
        }
        return changed;
    }

    private String getFromMap(Map<String, String> map, String key, boolean print, int printIndent, boolean secret) {
        String value = map.get(key);
        if (value != null) {
            if (print) {
                System.out.println(this.repeat(printIndent, ' ') + key + " = " + (secret ? "****" : value));
            }
        }
        return value;
    }

    //--------------------------------------------------------------------------

    private String formatValue(String key, String value, int printIndent, String prefix) {
       return this.repeat(printIndent, ' ') + prefix + key + " = " + value;
    }

    private String repeat(int count, char ch) {
        if (count > 0) {
            return String.format("%0" + count + "d", 0).replace('0', ch);
        } else {
            return "";
        }
    }
}
