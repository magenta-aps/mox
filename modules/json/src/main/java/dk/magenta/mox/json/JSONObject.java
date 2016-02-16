package dk.magenta.mox.json;

import org.json.JSONException;

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
        return (JSONObject) super.getJSONObject(key);
    }

    @Override
    public JSONArray getJSONArray(String key) {
        return (JSONArray) super.getJSONArray(key);
    }

    @Override
    public JSONObject optJSONObject(String key) {
        return (JSONObject) super.optJSONObject(key);
    }

    @Override
    public JSONArray optJSONArray(String key) {
        return (JSONArray) super.optJSONArray(key);
    }
/*
    public JSONObject extend(JSONObject other, boolean overwrite) {
        for (String key : other.keySet()) {
            if (this.has(key)) {

            } else {
                this.put(key, other.get(key));
            }
        }
    }*/
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
