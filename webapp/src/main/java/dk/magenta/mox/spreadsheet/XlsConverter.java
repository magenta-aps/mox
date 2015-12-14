package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.agent.ObjectType;
import org.apache.poi.hssf.usermodel.*;
import org.apache.poi.ss.usermodel.Cell;

import java.io.InputStream;
import java.util.Map;

/**
 * Created by lars on 26-11-15.
 */
public class XlsConverter extends SpreadsheetConverter {

    protected XlsConverter(Map<String, ObjectType> objectTypes) {
        super(objectTypes);
    }

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.ms-excel",
        };
    }

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        HSSFWorkbook document = new HSSFWorkbook(data);
        for (int i = 0; i < document.getNumberOfSheets(); i++) {
            HSSFSheet sheet = document.getSheetAt(i);
            String sheetName = sheet.getSheetName();
            for (int j = 0; j <= sheet.getLastRowNum(); j++) {
                SpreadsheetRow rowData = new SpreadsheetRow();
                if (j >= sheet.getFirstRowNum()) {
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
                /*if (DateUtil.isCellDateFormatted(cell)) {
                    return dateFormat.format(DateUtil.getJavaDate(cell.getNumericCellValue()));
                } else {*/
                    return "" + cell.getNumericCellValue();
                //}
            } else if (cellType == Cell.CELL_TYPE_BOOLEAN) {
                return "" + cell.getBooleanCellValue();
            }
        }
        return "";
    }
}
