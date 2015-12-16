package dk.magenta.mox.json;

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
        return (JSONObject) super.getJSONObject(index);
    }

    @Override
    public JSONArray getJSONArray(int index) {
        return (JSONArray) super.getJSONArray(index);
    }

    @Override
    public JSONObject optJSONObject(int index) {
        return (JSONObject) super.optJSONObject(index);
    }

    @Override
    public JSONArray optJSONArray(int index) {
        return (JSONArray) super.optJSONArray(index);
    }

}
