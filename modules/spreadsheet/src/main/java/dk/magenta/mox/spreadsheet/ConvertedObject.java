package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.util.*;

/**
 * Created by lars on 15-12-15.
 */
public class ConvertedObject extends HashMap<String, String> {

    public static final String EFFECT_INFINITY = "infinity";
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

    public JSONObject getJSON() throws MissingStructureException {
        System.out.println("--------------------------------------------------");
        JSONObject newjson = new JSONObject();

        Set<JSONObject> newcontainers = new HashSet<JSONObject>();
        JSONObject neweffectiveObject = new JSONObject();

        for (String key : this.keySet()) {
            if (!key.equalsIgnoreCase("operation")) {
                String value = this.get(key);
                StructurePath path = this.sheet.structure.getConversionPath(key);

                if (path == null) {
                    Structure structure = Structure.allStructures.get(this.sheet.name);
                    if (structure == null) {
                        log.error("No structure found in structure.json for " +
                                "sheet name '" + this.sheet.name + "'");
                        throw new MissingStructureException("No structure found in structure.json for " +
                                "sheet name '" + this.sheet.name + "'");
                    } else {
                        path = structure.getConversionPath(key);
                    }
                }

                if (path == null) {
                    if (value != null && !value.isEmpty()) {
                        log.warn("No structure path for header " + key + " in sheet " + this.sheet.name);
                    }
                } else {
                    //System.out.println("----------------");
                    //System.out.println("value: "+value);
                    //System.out.println("path: "+path);

                    if (path.get(0).equalsIgnoreCase("virkning")) {
                        if (value == null || value.isEmpty()) {
                            value = EFFECT_INFINITY;
                        }
                        this.sheet.structure.addConversion(neweffectiveObject, key, value);
                    } else {
                        if (value != null && !value.isEmpty()) {
                            JSONObject leaf = this.sheet.structure.addConversion(newjson, key, value);
                            if (!key.equalsIgnoreCase("objektID") && !key.equalsIgnoreCase("Søgeord_beskrivelse") && !key.equalsIgnoreCase("Søgeord_kategori") && !key.equalsIgnoreCase("Søgeord")) {
                                newcontainers.add(leaf);
                            }
                        }
                    }
                }

            }
        }
        for (JSONObject container : newcontainers) {
            container.extend(neweffectiveObject, true, false);
        }
        return newjson;
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

    public JSONObject mergeJSON(JSONObject a, JSONObject b, boolean overwrite, boolean verbose, StructurePath currentPath) {
        if (verbose) System.out.println("Adding "+b.toString()+"\nto "+a.toString());
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
                        this.mergeJSON(child, otherChild, overwrite, verbose, path);
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
                            if (this.getStructure().isMergeList(path)) {
                                JSONObject crunch;
                                if (achild.length() == 0) {
                                    crunch = new JSONObject();
                                    achild.put(crunch);
                                } else {
                                    crunch = achild.getJSONObject(0);
                                }
                                for (int i=0; i<otherChild.length(); i++) {
                                    this.mergeJSON(crunch, otherChild.getJSONObject(i), overwrite, verbose, path);
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
