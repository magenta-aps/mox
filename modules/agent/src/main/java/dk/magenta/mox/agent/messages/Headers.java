package dk.magenta.mox.agent.messages;

import java.util.HashMap;
import java.util.Map;

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
}
