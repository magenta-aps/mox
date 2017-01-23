package dk.magenta.mox.agent;

import dk.magenta.mox.agent.json.JSONArray;
import dk.magenta.mox.agent.json.JSONObject;
import org.json.JSONException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Created by lars on 23-09-15.
 *
 * Map that holds multiple values for a given key
 */
public class ParameterMap<K,V> extends HashMap<K,ArrayList<V>> {

    public ArrayList<V> add(K key) {
        ArrayList<V> list = this.get(key);
        if (list == null) {
            list = new ArrayList<V>();
            this.put(key, list);
        }
		return list;
    }

    public void add(K key, V value) {
        this.add(key).add(value);
    }

    public JSONObject toJSON() {
        JSONObject jsonObject = new JSONObject();
        for (K key : this.keySet()) {
            List<V> values = this.get(key);
            if (values != null) {
                JSONArray jsonArray = new JSONArray();
                for (V value : values) {
                    jsonArray.put((String) value);
                }
                jsonObject.put((String) key, jsonArray);
            }
        }
        return jsonObject;
    }

    public void populateFromJSON(JSONObject jsonObject) {
        for (String key : jsonObject.keySet()) {
            try {
                JSONArray arrayValue = jsonObject.getJSONArray(key);
                if (arrayValue != null) {
                    for (int i=0; i<arrayValue.length(); i++) {
                        this.add((K) key, (V) arrayValue.get(i));
                    }
                }
            } catch (JSONException e) {}
            try {
                String stringValue = jsonObject.getString(key);
                if (stringValue != null) {
                    this.add((K) key, (V) stringValue);
                }
            } catch (JSONException e) {}
        }
    }

    public V getAtIndex(K key, int index) {
        if (this.containsKey(key)) {
            List<V> values = this.get(key);
            if (values.size() > index) {
                return values.get(index);
            }
        }
        return null;
    }

    public V getFirst(K key) {
        return this.getAtIndex(key, 0);
    }

    public Map<K,V> getFirstMap() {
        HashMap<K,V> map = new HashMap<>();
        for (K key : this.keySet()) {
            map.put(key, this.getFirst(key));
        }
        return map;
    }
}
