package dk.magenta.mox;

import dk.magenta.mox.agent.ObjectType;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;

import org.odftoolkit.simple.SpreadsheetDocument;
import org.odftoolkit.simple.table.Cell;
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
                    Cell cell = row.getCellByIndex(k);
                    rowData.add(getCellString(cell));
                }
                spreadsheetConversion.addRow(sheetName, rowData, j==0);
            }
        }
        return spreadsheetConversion;
    }

    private static String getCellString(Cell cell) {
        if ("date".equals(cell.getValueType())) {
            return dateFormat.format(cell.getDateValue());
        }
        return cell.getStringValue();
    }
}
