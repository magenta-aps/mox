package dk.magenta.mox.agent;

import java.util.Map;

import org.json.JSONObject;

public interface MessageReceivedCallback {
    void run(Map<String, Object> headers, JSONObject jsonObject);
}
