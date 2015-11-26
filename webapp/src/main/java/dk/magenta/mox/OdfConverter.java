package dk.magenta.mox;

import org.json.JSONArray;
import java.io.InputStream;
import java.util.Iterator;

import org.odftoolkit.simple.SpreadsheetDocument;
import org.odftoolkit.simple.table.Row;
import org.odftoolkit.simple.table.Table;

/**
 * Created by lars on 26-11-15.
 */
public class OdfConverter extends SpreadsheetConverter {

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.oasis.opendocument.spreadsheet"
        };
    };

    public JSONArray convert(InputStream data) throws Exception {
        SpreadsheetDocument document = SpreadsheetDocument.loadDocument(data);
        int sheetCount = document.getSheetCount();
        for (int i=0; i<sheetCount; i++) {
            Table sheet = document.getSheetByIndex(i);
            for (Iterator<Row> rowIterator = sheet.getRowIterator(); rowIterator.hasNext(); ) {
                Row row = rowIterator.next();

            }
        }
        return new JSONArray();
    }
}
