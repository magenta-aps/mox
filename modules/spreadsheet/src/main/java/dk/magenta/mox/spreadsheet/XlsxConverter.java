package dk.magenta.mox.spreadsheet;

import org.apache.poi.xssf.usermodel.*;

import java.io.InputStream;

/**
 * Created by lars on 26-11-15.
 */
public class XlsxConverter extends XlsConverter {

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "application/wps-office.xlsx"
        };
    }

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        XSSFWorkbook document = new XSSFWorkbook(data);
        int sheetCount = document.getNumberOfSheets();
        for (int i = 0; i < sheetCount; i++) {
            XSSFSheet sheet = document.getSheetAt(i);
            String sheetName = sheet.getSheetName();
            for (int j = 0; j <= sheet.getLastRowNum(); j++) {
                SpreadsheetRow rowData = new SpreadsheetRow();
                if (j >= sheet.getFirstRowNum()) {
                    XSSFRow row = sheet.getRow(j);
                    int firstCell = row.getFirstCellNum();
                    int lastCell = row.getLastCellNum();
                    for (int k = 0; k < lastCell; k++) {
                        rowData.add((k < firstCell) ? "" : getCellString(row.getCell(k)));
                    }
                }
                spreadsheetConversion.addRow(sheetName, rowData, j==0);
            }
        }
        return spreadsheetConversion;
    }

}
