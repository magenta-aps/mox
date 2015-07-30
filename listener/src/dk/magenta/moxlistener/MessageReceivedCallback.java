package dk.magenta.moxlistener;

import java.util.Map;

import org.json.JSONObject;

/**
 * Created by lars on 30-07-15.
 */
public interface MessageReceivedCallback {
    void run(Map<String, Object> headers, JSONObject jsonObject);
}
