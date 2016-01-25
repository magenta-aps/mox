package dk.magenta.mox.agent.messages;

import org.json.JSONObject;

import java.net.URL;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by lars on 22-01-16.
 */
public class UploadedDocumentMessage extends DocumentMessage {

    public static final String KEY_FILENAME = "filename";
    public static final String KEY_URL = "url";

    private String filename;
    private URL retrievalUrl;

    public UploadedDocumentMessage(String filename, URL retrievalUrl, String authorization) {
        super(authorization);
        this.filename = filename;
        this.retrievalUrl = retrievalUrl;
    }

    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        object.put(KEY_FILENAME, this.filename);
        object.put(KEY_URL, this.retrievalUrl.toString());
        return object;
    }

    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_TYPE, Message.HEADER_TYPE_VALUE_MANUAL);
        headers.put(Message.HEADER_OBJECTREFERENCE, this.retrievalUrl.toString());
        return headers;
    }
}
