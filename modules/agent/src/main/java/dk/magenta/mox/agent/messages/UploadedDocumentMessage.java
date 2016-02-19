package dk.magenta.mox.agent.messages;

import dk.magenta.mox.agent.MessageInterface;
import dk.magenta.mox.json.JSONObject;

import java.net.MalformedURLException;
import java.net.URL;

/**
 * Created by lars on 22-01-16.
 */
public class UploadedDocumentMessage extends Message {

    public static final String KEY_FILENAME = "filename";
    public static final String KEY_URL = "url";

    private String filename;
    private URL retrievalUrl;

    public UploadedDocumentMessage(String filename, URL retrievalUrl, String authorization) {
        super(authorization);
        this.filename = filename;
        this.retrievalUrl = retrievalUrl;
    }

    public UploadedDocumentMessage(String filename, String retrievalUrl, String authorization) throws MalformedURLException {
        this(filename, new URL(retrievalUrl), authorization);
    }

    public JSONObject getJSON() {
        JSONObject object = super.getJSON();
        object.put(KEY_FILENAME, this.filename);
        object.put(KEY_URL, this.retrievalUrl.toString());
        return object;
    }

    public static UploadedDocumentMessage parse(Headers headers, JSONObject data) {
        String operationName = (String) headers.get(MessageInterface.HEADER_OPERATION);
        if ("upload".equalsIgnoreCase(operationName)) {
            String authorization = (String) headers.get(MessageInterface.HEADER_AUTHORIZATION);
            if (data != null) {
                JSONObject jsonObject = new JSONObject();
                String filename = jsonObject.getString(KEY_FILENAME);
                String retrievalUrl = jsonObject.getString(KEY_URL);
                try {
                    return new UploadedDocumentMessage(filename, retrievalUrl, authorization);
                } catch (MalformedURLException e) {
                }
            }
        }
        return null;
    }

    @Override
    public Headers getHeaders() {
        Headers headers = super.getHeaders();
        headers.put(Message.HEADER_OBJECTTYPE, HEADER_OBJECTTYPE_VALUE_DOCUMENT);
        headers.put(Message.HEADER_TYPE, Message.HEADER_TYPE_VALUE_MANUAL);
        headers.put(Message.HEADER_OBJECTREFERENCE, this.retrievalUrl.toString());
        return headers;
    }
}
