package dk.magenta.mox.agent;

import java.util.Map;
import java.util.concurrent.Future;

import org.json.JSONObject;

public interface MessageHandler {
    Future<String> run(Map<String, Object> headers, JSONObject jsonObject);
}
