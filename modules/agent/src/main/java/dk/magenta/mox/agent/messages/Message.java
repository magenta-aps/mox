package dk.magenta.mox.agent.messages;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Created by lars on 25-01-16.
 */
public class Message {

    public static final String HEADER_AUTHORIZATION = "autorisation";
    public static final String HEADER_MESSAGEID = "beskedID";
    public static final String HEADER_MESSAGEVERSION = "beskedversion";
    public static final String HEADER_OBJECTREFERENCE = "objektreference";
    public static final String HEADER_OBJECTTYPE = "objekttype";

    public static final String HEADER_TYPE = "type";
    public static final String HEADER_TYPE_VALUE_MANUAL = "Manuel";

    public static final long version = 1L;

    private String authorization;

    public Message(String authorization) {
        this.authorization = authorization;
    }


    public JSONObject getJSON() {
        JSONObject object = new JSONObject();
        return object;
    }
    public Headers getHeaders() {
        Headers headers = new Headers();
        headers.put(HEADER_AUTHORIZATION, this.authorization);
        headers.put(HEADER_MESSAGEID, UUID.randomUUID().toString());
        headers.put(HEADER_MESSAGEVERSION, version);
        return headers;
    }
}
