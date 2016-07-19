package dk.magenta.mox.moxtabel;

import org.apache.log4j.Logger;

import java.util.*;

/**
 * Created by lars on 27-11-15.
 */
public class SpreadsheetConversion {

    private static Logger log = Logger.getLogger(SpreadsheetConversion.class);

    private static String[] idHeaderNames = new String[] {
            "objektID",
            "BrugervendtNoegle"
    };
    private static String operationHeaderName = "operation";
    private static Map<String, String> operations;

    static {
        operations = new HashMap<String, String>();
        operations.put("opret","create");
        operations.put("ret","update");
        operations.put("import","import");
        operations.put("slet","delete");
        operations.put("passiver","passivate");
        operations.put("læs","read");
        operations.put("list","list");
        operations.put("søg","search");
        operations.put("ajour","ajour");
    }

    /**
     * Data chunk for all objects in a particular sheet
     * */
    class SheetData {
        public String name;

        // Spreadsheet column header
        public SpreadsheetRow header;

        // Stores the indexes in which the object ID may be found
        public ArrayList<Integer> headerIdIndexes;

        // Stores the index in which the operation may be found
        public int headerOperationIndex = 0;

        // Key conversion: Maps spreadsheet column headers to json path
        public Structure structure;

        // A collection of objects obtained from the spreadsheet
        public HashMap<String, ArrayList<ConvertedObject>> objects = new HashMap<String, ArrayList<ConvertedObject>>();
    }

    private HashMap<String, SheetData> sheets = new HashMap<String, SheetData>();

    /**
     * Gets a sheet from internal map, creating it if it doesn't exist
     * */
    public SheetData getSheet(String sheetName) {
        if (!this.sheets.containsKey(sheetName)) {
            SheetData sheet = new SheetData();
            sheet.name = sheetName;
            sheet.structure = Structure.allStructures.get(sheetName);
            this.sheets.put(sheetName, sheet);
        }
        return this.sheets.get(sheetName);
    }

    /**
     * Receive a row from a spreadsheet and parses it.
     * */
    protected void addRow(String sheetName, SpreadsheetRow rowData, boolean firstRow) {
        if (rowData != null && !rowData.isEmpty()) {
            if (sheetName.equalsIgnoreCase("besked")) {
            } else if (sheetName.equalsIgnoreCase("struktur")) {
                //this.addStructureRow(rowData);
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
    /*private void addStructureRow(SpreadsheetRow row) {
        String objectTypeName = row.get(0);
        String spreadsheetKey = row.get(1);
        SheetData sheet = this.getSheet(objectTypeName);
        ArrayList<String> values = new ArrayList<String>(row.subList(2, row.size()));
        sheet.structure.put(spreadsheetKey, values);
    }*/

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
        int index = row.indexOf(operationHeaderName);
        if (index != -1) {
            sheet.headerOperationIndex = index;
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
            String id = null;
            for (Integer idIndex : sheet.headerIdIndexes) {
                id = row.get(idIndex);
                if (!id.isEmpty()) {
                    break;
                }
            }

            String operation = row.get(sheet.headerOperationIndex);

            if (id == null || id.isEmpty()) {
                log.warn("No id for object row " + row);
            } else if (operation == null || operation.isEmpty()) {
                log.warn("No operation for object row (id='" + id + "')");
            } else if (!operations.containsKey(operation) && !operations.containsValue(operation)) {
                log.warn("Unrecognized operation for object row (id='" + id + "')");
            } else {
                if (operations.containsKey(operation)) {
                    operation = operations.get(operation);
                }
                ArrayList<ConvertedObject> objects = sheet.objects.get(id);
                if (objects == null) {
                    objects = new ArrayList<>();
                    sheet.objects.put(id, objects);
                }
                ConvertedObject object = null;
                if (operation.equalsIgnoreCase("update")) {
                    for (ConvertedObject o : objects) {
                        if (o.getOperation().equalsIgnoreCase(operation)) {
                            object = o;
                            break;
                        }
                    }
                }
                if (object == null) {
                    object = new ConvertedObject(sheet, id, operation);
                    objects.add(object);
                }
                object.add(row.toMap(headerRow));
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

    public List<ConvertedObject> getObjectRows(String sheetName, String id) {
        SheetData sheet = this.sheets.get(sheetName);
        if (sheet == null) {
            throw new IllegalArgumentException("Invalid sheet name '"+sheetName+"'; not found in loaded data. Valid sheet names are: " + this.getSheetNames());
        } else {
            List<ConvertedObject> convertedObject = sheet.objects.get(id);
            if (convertedObject == null) {
                throw new IllegalArgumentException("Invalid object id '"+id+"'; not found in sheet '"+sheetName+"'. Valid object ids are: " + this.getObjectIds(sheetName));
            } else {
                return convertedObject;
            }
        }
    }

    /*
    * Return a mapping of ConvertedObjects by objecttype and objectId
    * */
    public Map<String, Map<String, List<ConvertedObject>>> getConvertedObjects() {
        HashMap<String, Map<String, List<ConvertedObject>>> out = new HashMap<String, Map<String, List<ConvertedObject>>>();
        for (String sheetName : this.getSheetNames()) {
            HashMap<String, List<ConvertedObject>> sheetObjects = new HashMap<String, List<ConvertedObject>>();
            for (String objectId : this.getObjectIds(sheetName)) {
                sheetObjects.put(objectId, this.getObjectRows(sheetName, objectId));
            }
            out.put(sheetName, sheetObjects);
        }
        return out;
    }
}
