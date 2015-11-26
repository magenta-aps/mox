package dk.magenta.mox;

import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.xssf.eventusermodel.XSSFReader;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;
import org.apache.poi.xssf.usermodel.XSSFDataFormat;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.json.JSONArray;

import java.io.InputStream;

/**
 * Created by lars on 26-11-15.
 */
public class XlsxConverter extends SpreadsheetConverter {

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "application/wps-office.xlsx"
        };
    }

    public JSONArray convert(InputStream data) throws Exception {
        XSSFWorkbook document = new XSSFWorkbook(data);
        int sheetCount = document.getNumberOfSheets();
        for (int i=0; i<sheetCount; i++) {
            XSSFSheet sheet = document.getSheetAt(i);
            for (int j = sheet.getFirstRowNum(); j<sheet.getLastRowNum(); j++) {
                XSSFRow row = sheet.getRow(j);

            }
        }
        return new JSONArray();
    }
}
