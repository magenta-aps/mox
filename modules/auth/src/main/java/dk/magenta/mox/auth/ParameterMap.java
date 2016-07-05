package dk.magenta.mox.auth;

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
