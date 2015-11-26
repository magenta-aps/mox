package dk.magenta.mox;

import org.apache.poi.hssf.usermodel.HSSFRow;
import org.apache.poi.hssf.usermodel.HSSFSheet;
import org.apache.poi.hssf.usermodel.HSSFWorkbook;
import org.apache.poi.openxml4j.opc.OPCPackage;
import org.apache.poi.xssf.usermodel.XSSFRow;
import org.apache.poi.xssf.usermodel.XSSFSheet;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.json.JSONArray;

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

    public JSONArray convert(InputStream data) throws Exception {
        HSSFWorkbook document = new HSSFWorkbook(data);
        int sheetCount = document.getNumberOfSheets();
        for (int i=0; i<sheetCount; i++) {
            HSSFSheet sheet = document.getSheetAt(i);
            for (int j = sheet.getFirstRowNum(); j<sheet.getLastRowNum(); j++) {
                HSSFRow row = sheet.getRow(j);

            }
        }
        return new JSONArray();
    }
}
