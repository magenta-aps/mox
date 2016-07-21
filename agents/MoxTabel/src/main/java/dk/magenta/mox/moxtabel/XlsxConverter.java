package dk.magenta.mox.moxtabel;

import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.apache.poi.xssf.usermodel.*;

import java.io.File;
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
        return this.convert(new XSSFWorkbook(data));
    }
    public SpreadsheetConversion convert(File data) throws Exception {
        return this.convert((XSSFWorkbook) WorkbookFactory.create(data));
    }

    private SpreadsheetConversion convert(XSSFWorkbook document) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        int sheetCount = document.getNumberOfSheets();
        for (int i = 0; i < sheetCount; i++) {
            XSSFSheet sheet = document.getSheetAt(i);
            String sheetName = sheet.getSheetName();
            int firstRowIndex = sheet.getFirstRowNum();
            int rowCount = sheet.getLastRowNum() + 1;
            for (int j = 0; j < rowCount; j++) {
                SpreadsheetRow rowData = new SpreadsheetRow();
                if (j >= firstRowIndex) {
                    XSSFRow row = sheet.getRow(j);
                    if (row != null) {
                        int firstCell = row.getFirstCellNum();
                        int lastCell = row.getLastCellNum();
                        for (int k = 0; k < lastCell; k++) {
                            rowData.add((k < firstCell) ? "" : getCellString(row.getCell(k)));
                        }
                    }
                }
                spreadsheetConversion.addRow(sheetName, rowData, j==0);
            }
        }
        return spreadsheetConversion;
    }

}
