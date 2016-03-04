package dk.magenta.mox.agent.messages;

import java.util.HashMap;
import java.util.Map;
import dk.magenta.mox.agent.exceptions.MissingHeaderException;

/**
 * Created by lars on 25-01-16.
 */
public class Headers extends HashMap<String, Object> {
    public Headers(){
        super();
    }
    public Headers(Map<String, Object> base) {
        super(base);
    }

    public String optString(String key) {
        Object value = this.get(key);
        if (value != null) {
            return value.toString().trim();
        }
        return null;
    }

    public String getString(String key) throws MissingHeaderException {
        String value = this.optString(key);
        if (value == null) {
            throw new MissingHeaderException(key);
        }
        return value;
    }
}
