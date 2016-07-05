package dk.magenta.mox.moxtabel;
/*
import org.odftoolkit.simple.SpreadsheetDocument;
import org.odftoolkit.simple.table.Cell;
import org.odftoolkit.simple.table.Row;
import org.odftoolkit.simple.table.Table;
*/
import org.apache.log4j.Logger;

import org.jopendocument.dom.spreadsheet.*;

import java.io.File;

/**
 * Created by lars on 26-11-15.
 */
public class OdfConverter extends SpreadsheetConverter {

    private static Logger log = Logger.getLogger(SpreadsheetConverter.class);

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.oasis.opendocument.spreadsheet"
        };
    };

    public SpreadsheetConversion convert(File data) throws Exception {
        return this.convert(SpreadSheet.createFromFile(data));
    }

    private SpreadsheetConversion convert(SpreadSheet document) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        int sheetCount = document.getSheetCount();
        for (int i = 0; i < sheetCount; i++) {
            Sheet sheet = document.getSheet(i);
            String sheetName = sheet.getName();
            int rowCount = sheet.getRowCount();
            int columnCount = sheet.getColumnCount();
            int emptyRows = 0;
            for (int j = 0; j < rowCount; j++) {
                SpreadsheetRow rowData = new SpreadsheetRow(columnCount);
                for (int k = 0; k < columnCount; k++) {
                    Cell cell;
                    cell = sheet.getImmutableCellAt(k, j);
                    String contents = getCellString(cell);
                    if (contents == null || contents.isEmpty()) {
                        emptyRows++;
                    } else {
                        emptyRows = 0;
                    }
                    rowData.add(contents);
                }
                if (emptyRows == 0) {
                    spreadsheetConversion.addRow(sheetName, rowData, j == 0);
                } else if (emptyRows >= 10) {
                    break;
                }
            }
        }
        return spreadsheetConversion;
    }

    private static String getCellString(Cell cell) {
        return cell.getTextValue();
    }

/*
    public SpreadsheetConversion convert(InputStream data) throws Exception {
        return this.convert(SpreadsheetDocument.loadDocument(data));
    }
    public SpreadsheetConversion convert(File data) throws Exception {
        return this.convert(SpreadsheetDocument.loadDocument(data));
    }

    private SpreadsheetConversion convert(SpreadsheetDocument document) throws Exception {
        System.out.println("Converting");
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        int sheetCount = document.getSheetCount();
        for (int i = 0; i < sheetCount; i++) {
            Table sheet = document.getSheetByIndex(i);
            String sheetName = sheet.getTableName();
            int rowCount = sheet.getRowCount();
            for (int j = 0; j < rowCount; j++) {
                Row row = sheet.getRowByIndex(j);
                SpreadsheetRow rowData = new SpreadsheetRow(row.getCellCount());
                int cellCount = row.getCellCount();
                for (int k = 0; k < cellCount; k++) {
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
*/
}
