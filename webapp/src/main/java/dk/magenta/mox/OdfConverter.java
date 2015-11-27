package dk.magenta.mox;

import dk.magenta.mox.agent.ObjectType;
import org.json.JSONArray;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;

import org.odftoolkit.simple.SpreadsheetDocument;
import org.odftoolkit.simple.table.Row;
import org.odftoolkit.simple.table.Table;

/**
 * Created by lars on 26-11-15.
 */
public class OdfConverter extends SpreadsheetConverter {

    protected OdfConverter(Map<String, ObjectType> objectTypes) throws IOException {
        super(objectTypes);
    }

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.oasis.opendocument.spreadsheet"
        };
    };

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        SpreadsheetDocument document = SpreadsheetDocument.loadDocument(data);
        for (int i = 0; i < document.getSheetCount(); i++) {
            Table sheet = document.getSheetByIndex(i);
            String sheetName = sheet.getTableName();
            for (int j = 0; j < sheet.getRowCount(); j++) {
                Row row = sheet.getRowByIndex(j);
                SpreadsheetRow rowData = new SpreadsheetRow();
                for (int k = 0; k < row.getCellCount(); k++) {
                    rowData.add(row.getCellByIndex(k).getStringValue());
                }
                spreadsheetConversion.addRow(sheetName, rowData, j==0);
            }
        }
        return spreadsheetConversion;
    }
}
