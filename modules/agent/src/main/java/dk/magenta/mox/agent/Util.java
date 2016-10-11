package dk.magenta.mox.agent;

import dk.magenta.mox.agent.json.JSONObject;

import java.util.concurrent.Future;

/**
 * Created by lars on 23-09-15.
 */
public abstract class Util {

    public static String error(Exception e) {
        JSONObject errorObject = new JSONObject();
        errorObject.put("type", e.getClass().getSimpleName());
        errorObject.put("message", e.getMessage());
        errorObject.put("sourceProgram", "Mox agent listener");
        return errorObject.toString();
    }

    public static Future<String> futureError(Exception e) {
        return new ImmediateFuture<>(Util.error(e));
    }
}
