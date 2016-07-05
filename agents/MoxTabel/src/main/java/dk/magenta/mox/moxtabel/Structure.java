package dk.magenta.mox.moxtabel;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.io.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.UUID;

/**
 * Created by lars on 23-03-16.
 */
public class Structure {

    private static Logger log = Logger.getLogger(Structure.class);

    private HashMap<String, StructurePath> conversion;
    private ArrayList<StructurePath> lists;
    private ArrayList<StructurePath> mergelists;

    public Structure(JSONObject conversion, JSONArray lists, JSONArray mergelists) {
        this.conversion = new HashMap<>();
        for (String key : conversion.keySet()) {
            JSONArray valuePath = conversion.getJSONArray(key);
            this.conversion.put(key, new StructurePath(valuePath));
        }
        this.lists = new ArrayList<>();
        if (lists != null) {
            for (int i = 0; i < lists.length(); i++) {
                JSONArray list = lists.getJSONArray(i);
                this.lists.add(new StructurePath(list));
            }
        }
        this.mergelists = new ArrayList<>();
        if (mergelists != null) {
            for (int i = 0; i < mergelists.length(); i++) {
                JSONArray list = mergelists.getJSONArray(i);
                this.mergelists.add(new StructurePath(list));
            }
        }
    }

    public static Structure fromJSON(JSONObject object) {
        JSONObject conversion = object.getJSONObject("conversion");
        JSONArray lists = object.optJSONArray("lists");
        JSONArray mergelists = object.optJSONArray("mergelists");

        return new Structure(conversion, lists, mergelists);
    }

    public JSONObject toJSON() {
        JSONObject obj = new JSONObject();
        for (String key : this.conversion.keySet()) {
            StructurePath values = this.conversion.get(key);
            JSONArray list = new JSONArray();
            for (String item : values) {
                list.put(item);
            }
            obj.put(key, list);
        }
        return obj;
    }

    public StructurePath getConversionPath(String key) {
        return this.conversion.get(key);
    }
    public List<StructurePath> getLists() {
        return this.lists;
    }
    public boolean isList(StructurePath path) {
        for (StructurePath p : this.lists) {
            if (p.equals(path)) {
                return true;
            }
        }
        return false;
    }
    public boolean isMergeList(StructurePath path) {
        for (StructurePath p : this.mergelists) {
            if (p.equals(path)) {
                return true;
            }
        }
        return false;
    }

    private String interpretPathBranch(String pathKey, String value) {
        String[] pathKeys = pathKey.split("\\|");
        for (String key : pathKeys) {
            key = key.trim().toLowerCase();
            try {
                if (key.equals("uuid")) {
                    UUID.fromString(value);
                    return key;
                }
                if (key.equals("urn")) {
                    return key;
                }
            } catch (Exception e) {}
        }
        return pathKey;
    }

    public JSONObject addConversion(JSONObject base, String key, String value) {
        StructurePath path = this.getConversionPath(key);
        JSONObject ptr = base;
        for (int i=0; i<path.size(); i++) {

            StructurePath subPath = path.subPath(i);
            String pathKey = path.get(i);
            if (pathKey.contains("|")) {
                pathKey = this.interpretPathBranch(pathKey, value);
            }

            if (i == path.size()-1) {
                ptr.put(pathKey, value);
            } else {
                if (this.isList(subPath)) {
                    JSONArray arr = ptr.fetchJSONArray(pathKey);
                    if (arr.length() > 0) {
                        ptr = arr.getJSONObject(0);
                    } else {
                        ptr = new JSONObject();
                        arr.put(ptr);
                    }
                } else {
                    ptr = ptr.fetchJSONObject(pathKey);
                }
            }
        }
        return ptr;
    }


    public static HashMap<String, Structure> allStructures = new HashMap<String, Structure>();

    static {
        File structuresFile = new File("structure.json");
        try {
            log.info("Loading structure from "+structuresFile.getCanonicalPath());
        } catch (IOException e) {
            log.info("Loading structure from structure.json");
        }
        if (!structuresFile.exists()) {
            log.error("File "+structuresFile+" does not exist");
        } else if (!structuresFile.canRead()) {
            log.error("File "+structuresFile+" is not readable");
        } else {
            try {
                JSONObject structures = new JSONObject(structuresFile);
                for (String sheetname : structures.keySet()) {
                    allStructures.put(sheetname, Structure.fromJSON(structures.getJSONObject(sheetname)));
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
            log.info("Loaded "+allStructures.size()+" structure objects");
        }
    }
}

