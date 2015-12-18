package dk.magenta.mox.agent;

import org.json.JSONObject;

import java.util.Map;
import java.util.concurrent.Future;

/**
 * Created by lars on 04-08-15.
 */
public class PrintMessageHandler implements MessageHandler {

    public Future<String> run(Map<String, Object> headers, JSONObject jsonObject) {
        System.out.println("-------- Message received --------");
        System.out.println("headers:");
        if (headers == null || headers.isEmpty()) {
            System.out.println("    <none>");
        } else {
            for (String key : headers.keySet()) {
                System.out.println("    " + key + " = " + headers.get(key));
            }
        }
        System.out.println("body:");
        System.out.println(jsonObject.toString(2));
        return new ImmediateFuture<String>("");
    }
}
