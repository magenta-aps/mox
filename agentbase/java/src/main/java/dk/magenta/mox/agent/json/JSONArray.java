package dk.magenta.mox.agent.json;

import org.json.JSONException;

/**
 * Created by lars on 30-11-15.
 */
public class JSONArray extends org.json.JSONArray {

    public JSONArray() {
        super();
    }
    public JSONArray(String jsonString) {
        super(jsonString);
    }
    public JSONArray(org.json.JSONArray json) {
        super();
        if (json != null) {
            for (int i=0; i<json.length(); i++) {
                this.put(json.get(i));
            }
        }
    }

    public JSONObject fetchJSONObject(int index) {
        if (!this.has(index)) {
            JSONObject object = new JSONObject();
            this.put(index, object);
            return object;
        }
        return this.getJSONObject(index);
    }

    public JSONArray fetchJSONArray(int index) {
        if (!this.has(index)) {
            JSONArray object = new JSONArray();
            this.put(index, object);
            return object;
        }
        return this.getJSONArray(index);
    }

    public boolean has(int index) {
        return (index >= 0 && index < this.length());
    }

    @Override
    public JSONObject getJSONObject(int index) {
        org.json.JSONObject object = super.getJSONObject(index);
        if (object instanceof JSONObject) {
            return (JSONObject) object;
        } else {
            JSONObject con = new JSONObject(object);
            this.put(index, con);
            return con;
        }
    }

    @Override
    public JSONArray getJSONArray(int index) {
        org.json.JSONArray array = super.getJSONArray(index);
        if (array instanceof JSONArray) {
            return (JSONArray) array;
        } else {
            JSONArray con = new JSONArray(array);
            this.put(index, con);
            return con;
        }
    }

    @Override
    public JSONObject optJSONObject(int index) {
        try {
            return this.getJSONObject(index);
        } catch (JSONException e) {
            return null;
        }
    }

    @Override
    public JSONArray optJSONArray(int index) {
        try {
            return this.getJSONArray(index);
        } catch (JSONException e) {
            return null;
        }
    }

    public void addAll(JSONArray other) {
        for (int i=0; i<other.length(); i++) {
            this.put(other.get(i));
        }
    }

}
