package dk.magenta.mox;

import dk.magenta.mox.json.JSONArray;
import dk.magenta.mox.json.JSONObject;

import java.util.*;

/**
 * Created by lars on 27-11-15.
 */
class SpreadsheetConversion {

    private static String[] idHeaderNames = new String[] {
            "objektID",
            "BrugervendtNoegle"
    };

    /**
     * Data chunk for all objects in a particular sheet
     * */
    class SheetData {
        // Spreadsheet column header
        public SpreadsheetRow header;
        // Stores the indexes in which the object ID may be found
        public ArrayList<Integer> headerIdIndexes;
        // Key conversion: Maps spreadsheet column headers to json path
        public HashMap<String, ArrayList<String>> structure = new HashMap<String, ArrayList<String>>();
        // A collection of objects obtained from the spreadsheet
        public HashMap<String, HashMap<String,String>> objects = new HashMap<String, HashMap<String,String>>();
    }

    private HashMap<String, SheetData> sheets = new HashMap<String, SheetData>();

    /**
     * Gets a sheet from internal map, creating it if it doesn't exist
     * */
    private SheetData getSheet(String sheetName) {
        if (!this.sheets.containsKey(sheetName)) {
            this.sheets.put(sheetName, new SheetData());
        }
        return this.sheets.get(sheetName);
    }

    /**
     * Receive a row from a spreadsheet and parses it.
     * */
    public void addRow(String sheetName, SpreadsheetRow rowData, boolean firstRow) {
        if (rowData != null && !rowData.isEmpty()) {
            if (sheetName.equalsIgnoreCase("besked")) {
            } else if (sheetName.equalsIgnoreCase("struktur")) {
                this.addStructureRow(rowData);
            } else if (sheetName.equalsIgnoreCase("lister")) {
            } else {
                if (firstRow) {
                    this.addObjectHeaderRow(sheetName, rowData);
                } else {
                    this.addObjectRow(sheetName, rowData);
                }
            }
        }
    }

    /**
     * Parses a structure row
     * */
    private void addStructureRow(SpreadsheetRow row) {
        String objectTypeName = row.get(0);
        String spreadsheetKey = row.get(1);
        SheetData sheet = this.getSheet(objectTypeName);
        ArrayList<String> values = new ArrayList<String>(row.subList(2, row.size()));
        sheet.structure.put(spreadsheetKey, values);
    }

    /**
     * Parses an object sheet header row
     * */
    private void addObjectHeaderRow(String sheetName, SpreadsheetRow row) {
        SheetData sheet = this.getSheet(sheetName);
        sheet.header = row;
        sheet.headerIdIndexes = new ArrayList<Integer>();
        for (String idKey : idHeaderNames) {
            int index = row.indexOf(idKey);
            if (index != -1) {
                sheet.headerIdIndexes.add(index);
            }
        }
    }

    /**
     * Parses an object row
     * */
    private void addObjectRow(String sheetName, SpreadsheetRow row) {
        SheetData sheet = this.getSheet(sheetName);
        SpreadsheetRow headerRow = sheet.header;
        if (headerRow == null) {
            // Error: header not loaded
        } else {
            for (int i=0; i<row.size(); i++) {
                String value = row.get(i);
                String tag = headerRow.get(i);
                String id = null;
                for (Integer idIndex : sheet.headerIdIndexes) {
                    id = row.get(idIndex);
                    if (!id.isEmpty()) {
                        break;
                    }
                }
                if (id != null && !id.isEmpty()) {
                    HashMap<String, String> object = sheet.objects.get(id);
                    if (object == null) {
                        object = new HashMap<String, String>();
                        sheet.objects.put(id, object);
                    }
                    object.put(tag, value);
                }
            }
        }
    }

    public Set<String> getSheetNames() {
        return new HashSet<String>(this.sheets.keySet());
    }

    public Set<String> getObjectIds(String sheetName) {
        SheetData sheet = this.sheets.get(sheetName);
        if (sheet != null) {
            return new HashSet<String>(sheet.objects.keySet());
        }
        return null;
    }

    public JSONObject getConvertedObject(String sheetName, String id) {
        SheetData sheet = this.sheets.get(sheetName);
        if (sheet == null) {
            throw new IllegalArgumentException("Invalid sheet name '"+sheetName+"'; not found in loaded data. Valid sheet names are: " + this.getSheetNames());
        } else {
            HashMap<String, String> objectData = sheet.objects.get(id);
            if (objectData == null) {
                throw new IllegalArgumentException("Invalid object id '"+id+"'; not found in sheet '"+sheetName+"'. Valid object ids are: " + this.getObjectIds(sheetName));
            } else {
                JSONObject output = new JSONObject();

                Set<JSONObject> containers = new HashSet<JSONObject>();
                JSONObject effectiveObject = new JSONObject();

                for (String key : objectData.keySet()) {
                    String value = objectData.get(key);
                    List<String> path = sheet.structure.get(key);
                    System.out.println(sheetName+"."+key+" / "+path+" = "+value);

                    if (path == null) {
                        System.out.println("No structure path for header "+key+" in sheet "+sheetName);
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
                                output.put(pathLevel2, value);
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

                                JSONObject objectLevel1 = output.fetchJSONObject(pathLevel1);
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
                                System.out.println("Unrecognized pathlevel1: "+pathLevel1);
                            }

                        }
                    }
                }
                for (JSONObject container : containers) {
                    container.put("virkning", effectiveObject);
                }
                return output;
            }
        }
    }


}
