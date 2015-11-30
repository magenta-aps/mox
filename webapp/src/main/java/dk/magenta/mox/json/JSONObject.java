package dk.magenta.mox.json;

/**
 * Created by lars on 30-11-15.
 */
public class JSONObject extends org.json.JSONObject {

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


    public JSONObject getJSONObject(String key) {
        return (JSONObject) super.getJSONObject(key);
    }

    public JSONArray getJSONArray(String key) {
        return (JSONArray) super.getJSONArray(key);
    }

    public JSONObject optJSONObject(String key) {
        return (JSONObject) super.optJSONObject(key);
    }

    public JSONArray optJSONArray(String key) {
        return (JSONArray) super.optJSONArray(key);
    }
}
