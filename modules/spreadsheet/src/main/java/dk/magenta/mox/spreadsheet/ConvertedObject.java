package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;
import org.apache.log4j.Logger;

import java.util.*;

/**
 * Created by lars on 15-12-15.
 */
public class ConvertedObject extends HashMap<String, String> {

    private static Logger log = Logger.getLogger(ConvertedObject.class);

    private SpreadsheetConversion.SheetData sheet;
    private String id;
    private String operation;

    public ConvertedObject(SpreadsheetConversion.SheetData sheet, String id, String operation) {
        this.sheet = sheet;
        this.id = id;
        this.operation = operation;
    }

    public JSONObject getJSON() {
        JSONObject json = new JSONObject();

        Set<JSONObject> containers = new HashSet<JSONObject>();
        JSONObject effectiveObject = new JSONObject();

        for (String key : this.keySet()) {
            if (!key.equalsIgnoreCase("operation")) {
                String value = this.get(key);
                List<String> path = this.sheet.structure.get(key);

                if (path == null) {
                    log.warn("No structure path for header " + key + " in sheet " + this.sheet.name);
                } else {
                    String pathLevel1 = path.get(0);

                    if (pathLevel1.equalsIgnoreCase("virkning")) {
                        if (key.equalsIgnoreCase("fra")) {
                            effectiveObject.put("from", value);
                        } else if (key.equalsIgnoreCase("til")) {
                            effectiveObject.put("to", value);
                        }
                    } else if (path.size() >= 2) {
                        String pathLevel2 = path.get(1);
                        List<String> subPath = path.subList(2, path.size());
                        if (pathLevel1.equalsIgnoreCase("registrering")) {
                            json.put(pathLevel2, value);
                        } else if (pathLevel1.equalsIgnoreCase("attributter") || pathLevel1.equalsIgnoreCase("tilstande") || pathLevel1.equalsIgnoreCase("relationer")) {

                            if (pathLevel1.equalsIgnoreCase("relationer")) {
                                String firstSubPath = subPath.isEmpty() ? null : subPath.get(0);
                                if (firstSubPath != null) {
                                    if (firstSubPath.equalsIgnoreCase("uuid")) {
                                        try {
                                            UUID.fromString(value);
                                        } catch (IllegalArgumentException e) {
                                            // It's not a valid uuid
                                            subPath = new ArrayList<String>(subPath);
                                            subPath.set(0, "urn");
                                            value = "urn: " + value;
                                        }
                                    } else if (firstSubPath.equalsIgnoreCase("objekttype")) {
                                        continue;
                                    }
                                }
                            }

                            JSONObject objectLevel1 = json.fetchJSONObject(pathLevel1);
                            JSONArray objectLevel2 = objectLevel1.fetchJSONArray(pathLevel2);
                            JSONObject container = objectLevel2.fetchJSONObject(0);
                            containers.add(container);

                            for (int i = 0; i < subPath.size(); i++) {
                                String pathKey = subPath.get(i);
                                if (i == subPath.size() - 1) {
                                    container.put(pathKey, value);
                                } else {
                                    container = container.fetchJSONObject(pathKey);
                                }
                            }
                        } else {
                            log.warn("Unrecognized path: " + this.sheet.name + "." + id + " => " + path + " = " + value + ". Ignoring.");
                        }
                    } else {
                        log.warn("Unrecognized path length: " + this.sheet.name + "." + id + " => " + path + " = " + value + ". Path must have at least two parts.");
                    }
                }
            }
        }
        for (JSONObject container : containers) {
            container.put("virkning", effectiveObject);
        }
        return json;
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
}
