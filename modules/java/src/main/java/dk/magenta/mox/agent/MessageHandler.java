package dk.magenta.mox.agent;

import java.util.concurrent.Future;

import dk.magenta.mox.agent.json.JSONObject;
import dk.magenta.mox.agent.messages.Headers;

public interface MessageHandler {
    Future<String> run(Headers headers, JSONObject jsonObject);
}
