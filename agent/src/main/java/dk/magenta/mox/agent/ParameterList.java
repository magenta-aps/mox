package dk.magenta.mox.agent;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

/**
 * Created by lars on 23-09-15.
 */
public class ParameterList<K,V> extends HashMap<K,ArrayList<V>> {
    public void add(K key, V value) {
        ArrayList list;
        if (!this.containsKey(key)) {
            list = new ArrayList<V>();
            this.put(key, list);
        } else {
            list = this.get(key);
        }
        list.add(value);
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
}
