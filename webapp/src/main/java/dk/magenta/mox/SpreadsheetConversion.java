package dk.magenta.mox;

import dk.magenta.mox.agent.ObjectType;
import org.apache.poi.ss.usermodel.Sheet;
import org.json.JSONArray;
import org.json.JSONObject;

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
                if (id != null) {
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
            // Error: invalid sheet name
        } else {
            HashMap<String, String> objectData = sheet.objects.get(id);
            if (objectData == null) {
                // Error: invalid id
            } else {
                JSONObject output = new JSONObject();

                Set<JSONObject> containers = new HashSet<JSONObject>();
                JSONObject effectiveObject = new JSONObject();

                for (String key : objectData.keySet()) {
                    String value = objectData.get(key);
                    List<String> path = sheet.structure.get(key);

                    if (path == null) {
                        System.out.println("No structure path for header "+key+" in sheet "+sheetName);
                    } else if (path.size() >= 2) {
                        String pathLevel1 = path.get(0);
                        String pathLevel2 = path.get(1);

                        List<String> subPath = path.subList(2, path.size());
                        
                        if (pathLevel1.equalsIgnoreCase("registrering")) {
                            output.append(pathLevel2, value);
                        } else if (pathLevel1.equalsIgnoreCase("virkning")) {
                            if (key.equalsIgnoreCase("fra")) {
                                effectiveObject.put("from", value);
                            }
                            if (key.equalsIgnoreCase("til")) {
                                effectiveObject.put("to", value);
                            }
                        } else if (pathLevel1.equalsIgnoreCase("attributter") || pathLevel1.equalsIgnoreCase("tilstande") || pathLevel1.equalsIgnoreCase("relationer")) {

                            JSONObject objectLevel1 = output.optJSONObject(pathLevel1); // attributter
                            if (objectLevel1 == null) {
                                objectLevel1 = new JSONObject();
                                output.put(pathLevel1, objectLevel1);
                            }
                            JSONArray objectLevel2 = objectLevel1.optJSONArray(pathLevel2); // klassifikationegenskaber
                            if (objectLevel2 == null) {
                                objectLevel2 = new JSONArray();
                                objectLevel1.put(pathLevel2, objectLevel2);
                            }



                            JSONObject container = objectLevel2.optJSONObject(0);
                            if (container == null) {
                                container = new JSONObject();
                                objectLevel2.put(container);
                                containers.add(container);
                            }
                            for (int i = 0; i < subPath.size(); i++) {
                                String pathKey = subPath.get(i);
                                if (i == subPath.size() - 1) {
                                    container.put(pathKey, value);
                                } else {
                                    if (!container.has(pathKey)) {
                                        container.put(pathKey, new JSONObject());
                                    }
                                    container = container.getJSONObject(pathKey);
                                }
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



        return null;
    }


}
