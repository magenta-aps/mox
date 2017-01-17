package dk.magenta.mox.moxtabel;

import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.WorkbookFactory;

import java.io.File;
import java.io.InputStream;

/**
 * Created by lars on 26-11-15.
 */
public class XlsConverter extends SpreadsheetConverter {

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.ms-excel",
        };
    }

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        return this.convert(new HSSFWorkbook(data));
    }
    public SpreadsheetConversion convert(File data) throws Exception {
        return this.convert((HSSFWorkbook) WorkbookFactory.create(data));
    }

    private SpreadsheetConversion convert(HSSFWorkbook document) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        for (int i = 0; i < document.getNumberOfSheets(); i++) {
            HSSFSheet sheet = document.getSheetAt(i);
            String sheetName = sheet.getSheetName();
            int rowCount = sheet.getLastRowNum() + 1;
            int firstRowIndex = sheet.getFirstRowNum();
            for (int j = 0; j < rowCount; j++) {
                SpreadsheetRow rowData = new SpreadsheetRow();
                if (j >= firstRowIndex) {
                    HSSFRow row = sheet.getRow(j);
                    int firstCell = row.getFirstCellNum();
                    int lastCell = row.getLastCellNum();
                    for (int k = 0; k < lastCell; k++) {
                        rowData.add(row.getCell(k) == null ? "" : getCellString(row.getCell(k)));
                    }
                }
                spreadsheetConversion.addRow(sheetName, rowData, j==0);
            }
        }
        return spreadsheetConversion;
    }

    protected static String getCellString(Cell cell) {
        if (cell != null) {
            int cellType = cell.getCellType();
            if (cellType == Cell.CELL_TYPE_STRING) {
                return cell.getStringCellValue();
            } else if (cellType == Cell.CELL_TYPE_NUMERIC) {
                if (DateUtil.isCellDateFormatted(cell)) {
                    return dateFormat.format(DateUtil.getJavaDate(cell.getNumericCellValue()));
                } else {
                    double value = cell.getNumericCellValue();
                    if (value == Math.floor(value)) {
                        return String.valueOf((long) value);
                    } else {
                        return String.valueOf(value);
                    }
                }
            } else if (cellType == Cell.CELL_TYPE_BOOLEAN) {
                return "" + cell.getBooleanCellValue();
            }
        }
        return "";
    }
}
