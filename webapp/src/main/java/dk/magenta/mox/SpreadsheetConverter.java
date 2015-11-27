package dk.magenta.mox;

import org.json.JSONArray;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import dk.magenta.mox.agent.ObjectType;

import javax.servlet.ServletContext;

/**
 * Created by lars on 26-11-15.
 */
public abstract class SpreadsheetConverter {

    protected Map<String, ObjectType> objectTypes;

    protected SpreadsheetConverter(Map<String, ObjectType> objectTypes) {
        this.objectTypes = objectTypes;
    }

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

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        return null;
    }

    protected ObjectType getObjectType(String key) {
        ObjectType objectType = this.objectTypes.get(key);
        if (objectType == null) {
            for (String k : this.objectTypes.keySet()) {
                if (k.equalsIgnoreCase(key)) {
                    return this.objectTypes.get(k);
                }
            }
        }
        return objectType;
    }

    protected static boolean isRowdataEmpty(List<String> rowData) {
        if (rowData != null && !rowData.isEmpty()) {
            for (String s : rowData) {
                if (s != null && !s.isEmpty()) {
                    return false;
                }
            }
        }
        return true;
    }

}
