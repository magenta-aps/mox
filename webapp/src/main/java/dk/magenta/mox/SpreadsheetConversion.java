package dk.magenta.mox;

import org.apache.poi.ss.usermodel.Sheet;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by lars on 27-11-15.
 */
class SpreadsheetConversion {

    private static String[] idHeaderNames = new String[] {
            "objektID",
            "BrugervendtNoegle"
    };

    class SheetData {
        public HashMap<String, ArrayList<String>> structure = new HashMap<String, ArrayList<String>>();
        public SpreadsheetRow header;
        public ArrayList<Integer> headerIdIndexes;
        public HashMap<String, HashMap<String,String>> objects = new HashMap<String, HashMap<String,String>>();
    }

    private HashMap<String, SheetData> sheets = new HashMap<String, SheetData>();

    private SheetData getSheet(String sheetName) {
        if (!this.sheets.containsKey(sheetName)) {
            this.sheets.put(sheetName, new SheetData());
        }
        return this.sheets.get(sheetName);
    }

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


    public void addStructureRow(SpreadsheetRow row) {
        String objectTypeName = row.get(0);
        String spreadsheetKey = row.get(1);
        SheetData sheet = this.getSheet(objectTypeName);
        ArrayList<String> values = new ArrayList<String>(row.subList(2, row.size()));
        sheet.structure.put(spreadsheetKey, values);
    }

    public void addObjectHeaderRow(String sheetName, SpreadsheetRow row) {
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

    public void addObjectRow(String sheetName, SpreadsheetRow row) {
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


}
