package dk.magenta.mox.json;

import org.apache.commons.io.IOUtils;
import org.json.JSONException;

import java.io.*;
import java.util.HashSet;
import java.util.Objects;
import java.util.Set;

/**
 * Created by lars on 30-11-15.
 */
public class JSONObject extends org.json.JSONObject {

    public JSONObject() {
        super();
    }
    public JSONObject(String jsonString) {
        super(jsonString);
    }
    public JSONObject(org.json.JSONObject json) {
        super();
        for (String key : json.keySet()) {
            this.put(key, json.get(key));
        }
    }
    public JSONObject(InputStream input, String encoding) throws IOException {
        super();
        StringWriter writer = new StringWriter();
        IOUtils.copy(input, writer, encoding);
        String json = writer.toString();
        org.json.JSONObject obj = new org.json.JSONObject(json);
        for (String key : obj.keySet()) {
            this.put(key, obj.get(key));
        }
    }
    public JSONObject(InputStream input) throws IOException {
        this(input, "utf-8");
    }
    public JSONObject(File input) throws IOException {
        this(new FileInputStream(input));
    }

    public enum Keytype {
        DOESNT_EXIST,
        NULL,
        BOOLEAN,
        DOUBLE,
        INT,
        LONG,
        STRING,
        OBJECT,
        ARRAY
    }

    public JSONObject fetchJSONObject(String key) {
        if (!this.has(key)) {
            JSONObject object = new JSONObject();
            this.put(key, object);
            return object;
        }
        return this.getJSONObject(key);
    }
    public JSONArray fetchJSONArray(String key) {
        if (!this.has(key)) {
            JSONArray object = new JSONArray();
            this.put(key, object);
            return object;
        }
        return this.getJSONArray(key);
    }


    @Override
    public JSONObject getJSONObject(String key) {
        org.json.JSONObject object = super.getJSONObject(key);
        if (object instanceof JSONObject) {
            return (JSONObject) object;
        } else {
            JSONObject con = new JSONObject(object);
            this.put(key, con);
            return con;
        }
    }

    @Override
    public JSONArray getJSONArray(String key) {
        org.json.JSONArray array = super.getJSONArray(key);
        if (array instanceof JSONArray) {
            return (JSONArray) array;
        } else {
            JSONArray con = new JSONArray(array);
            this.put(key, con);
            return con;
        }
    }

    @Override
    public JSONObject optJSONObject(String key) {
        try {
            return this.getJSONObject(key);
        } catch (JSONException e) {
            return null;
        }
    }

    @Override
    public JSONArray optJSONArray(String key) {
        try {
            return this.getJSONArray(key);
        } catch (JSONException e) {
            return null;
        }
    }
/*
    public Keytype type(String key) {
        if (!this.has(key)) {
            return Keytype.DOESNT_EXIST;
        }
        try {
            this.getBoolean(key);
            return Keytype.BOOLEAN;
        } catch (JSONException e) {}
        try {
            this.getInt(key);
            return Keytype.INT;
        } catch (JSONException e) {}
        try {
            this.getDouble(key);
            return Keytype.DOUBLE;
        } catch (JSONException e) {}
        try {
            this.getLong(key);
            return Keytype.LONG;
        } catch (JSONException e) {}
        try {
            this.getString(key);
            return Keytype.STRING;
        } catch (JSONException e) {}
        try {
            this.getJSONArray(key);
            return Keytype.ARRAY;
        } catch (JSONException e) {}
        try {
            this.getJSONObject(key);
            return Keytype.OBJECT;
        } catch (JSONException e) {}

    }*/

}
