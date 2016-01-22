package dk.magenta.mox.upload;

import org.json.JSONObject;

import java.net.URL;

/**
 * Created by lars on 22-01-16.
 */
public class UploadedDocumentMessage {

    public static final String KEY_FILENAME = "filename";
    public static final String KEY_URL = "url";

    private String filename;
    private URL retrievalUrl;

    public UploadedDocumentMessage(String filename, URL retrievalUrl) {
        this.filename = filename;
        this.retrievalUrl = retrievalUrl;
    }

    public JSONObject toJSON() {
        JSONObject object = new JSONObject();
        object.put(KEY_FILENAME, this.filename);
        object.put(KEY_URL, this.retrievalUrl.toString());
        return object;
    }
}
