package dk.magenta.mox.agent;

import java.util.concurrent.Future;

import dk.magenta.mox.agent.messages.Headers;
import org.json.JSONObject;

public interface MessageHandler {
    Future<String> run(Headers headers, JSONObject jsonObject);
}
