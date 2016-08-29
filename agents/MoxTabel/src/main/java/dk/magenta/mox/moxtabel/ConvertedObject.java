package dk.magenta.mox.moxtabel;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.util.*;

/**
 * Created by lars on 15-12-15.
 */
public class ConvertedObject extends ArrayList<HashMap<String, String>> {

    private static final String EFFECT_INFINITY = "infinity";
    private static Logger log = Logger.getLogger(ConvertedObject.class);

    private SpreadsheetConversion.SheetData sheet;
    private String id;
    private String operation;

    public ConvertedObject(SpreadsheetConversion.SheetData sheet, String id, String operation) {
        this.sheet = sheet;
        this.id = id;
        this.operation = operation;
    }

    public Structure getStructure() {
        return this.sheet.structure;
    }

    public String getOperation() {
        return this.operation;
    }

    public String getSheetName() {
        return this.sheet.name;
    }

    public String getId() {
        return id;
    }


    public JSONObject getItemJSON(int index) throws MissingStructureException {
        JSONObject json = new JSONObject();

        Set<JSONObject> effectiveContainers = new HashSet<JSONObject>();
        JSONObject effectiveObject = new JSONObject();

        HashMap<String, String> row = this.get(index);
        String objectType = this.sheet.name;
        Structure structure = this.getStructure();

        for (String key : row.keySet()) {
            if (!key.equalsIgnoreCase("operation")) {
                String value = row.get(key);
                if (structure == null) {
                    log.error("No structure found in structure.json for sheet name '" + objectType + "'");
                    throw new MissingStructureException("No structure found in structure.json for sheet name '" + objectType + "'");
                }
                StructurePath path = structure.getConversionPath(key);

                if (path == null) {
                    path = structure.getConversionPath(key);
                }

                if (path == null) {
                    if (value != null && !value.isEmpty()) {
                        log.warn("No structure path for header " + key + " in sheet " + objectType);
                    }
                } else {
                    if (path.get(0).equalsIgnoreCase("virkning")) {
                        if (value == null || value.isEmpty()) {
                            value = EFFECT_INFINITY;
                        }
                        structure.addConversion(effectiveObject, key, value);
                    } else {
                        if (value != null && !value.isEmpty()) {
                            JSONObject leaf = structure.addConversion(json, key, value);
                            if (!key.equalsIgnoreCase("objektID") && !key.equalsIgnoreCase("Søgeord_beskrivelse") && !key.equalsIgnoreCase("Søgeord_kategori") && !key.equalsIgnoreCase("Søgeord")) {
                                effectiveContainers.add(leaf);
                            }
                        }
                    }
                }

            }
        }
        for (JSONObject container : effectiveContainers) {
            for (String key : effectiveObject.keySet()) {
                container.put(key, effectiveObject.get(key));
            }
        }
        return json;
    }

    public JSONObject getJSON() {
        JSONObject sum = new JSONObject();
        for (int i=0; i<this.size(); i++) {
            try {
                JSONObject convertedRow = this.getItemJSON(i);
                ConvertedObject.mergeJSON(sum, convertedRow, true, null, this.getStructure(), false);
            } catch (MissingStructureException e) {
                e.printStackTrace();
            }
        }
        return sum;
    }

    private static JSONObject mergeJSON(JSONObject a, JSONObject b, boolean overwrite, StructurePath currentPath, Structure structure, boolean verbose) {
        if (verbose) System.out.println("Adding "+b.toString()+"\nto "+a.toString());
        if (currentPath == null) {
            currentPath = new StructurePath();
        }
        for (String key : b.keySet()) {
            StructurePath path = (StructurePath) currentPath.clone();
            path.add(key);
            if (verbose) System.out.println("--------------");
            if (verbose) System.out.println("looking at key "+key);
            if (a.has(key)) {
                JSONObject child = a.optJSONObject(key);
                if (child != null) {
                    if (verbose) System.out.println("We have a sub-object here");
                    JSONObject otherChild = b.optJSONObject(key);
                    if (otherChild != null) {
                        if (verbose) System.out.println("Other object also has a sub-object here");
                        ConvertedObject.mergeJSON(child, otherChild, overwrite, path, structure, verbose);
                    } else {
                        if (verbose) System.out.println("Other object has a non-object here");
                        if (overwrite) {
                            child.put(key, b.get(key));
                        }
                    }
                } else {
                    JSONArray achild = a.optJSONArray(key);
                    if (achild != null) {
                        JSONArray otherChild = b.optJSONArray(key);
                        if (otherChild != null) {
                            if (structure.isMergeList(path)) {
                                JSONObject crunch;
                                if (achild.length() == 0) {
                                    crunch = new JSONObject();
                                    achild.put(crunch);
                                } else {
                                    crunch = achild.getJSONObject(0);
                                }
                                for (int i=0; i<otherChild.length(); i++) {
                                    ConvertedObject.mergeJSON(crunch, otherChild.getJSONObject(i), overwrite, path, structure, verbose);
                                }

                            } else {
                                achild.addAll(otherChild);
                            }
                        } else {
                            if (verbose) System.out.println("Other object has a non-array here");
                            child.put(key, b.get(key));
                        }
                    } else {
                        if (verbose)
                            System.out.println("We don't have a sub-object here");
                        a.put(key, b.get(key));
                    }
                }
            } else {
                if (verbose) System.out.println("Empty key, plain add");
                a.put(key, b.get(key));
            }
        }
        return a;
    }
}
