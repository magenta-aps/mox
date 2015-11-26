package dk.magenta.mox;

import org.json.JSONArray;

import java.io.InputStream;

/**
 * Created by lars on 26-11-15.
 */
public abstract class SpreadsheetConverter {

    protected String[] getApplicableContentTypes() {
        return new String[0];
    }

    public boolean applies(String contentType) {
        for (String type : this.getApplicableContentTypes()) {
            if (type.equals(contentType)) {
                return true;
            }
        }
        return false;
    }

    public JSONArray convert(InputStream data) throws Exception {
        return null;
    }
}
