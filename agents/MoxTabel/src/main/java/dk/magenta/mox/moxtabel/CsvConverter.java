package dk.magenta.mox.moxtabel;

import java.io.InputStream;
import java.util.Scanner;

/**
 * Created by lars on 26-11-15.
 */
public class CsvConverter extends SpreadsheetConverter {

    protected String[] getApplicableContentTypes() {
        return new String[]{
                "text/csv",
                "text/comma-separated-values"
        };
    };

    public SpreadsheetConversion convert(InputStream data) throws Exception {
        SpreadsheetConversion spreadsheetConversion = new SpreadsheetConversion();
        Scanner streamScanner = new Scanner(data, "UTF-8");
        streamScanner.useDelimiter("\n");
        while (streamScanner.hasNext()) {
            String line = streamScanner.next();
            // for sheet
                // for row
                    //SpreadsheetRow rowData = new SpreadsheetRow();
                    // for cell
                        //rowData.add(cellData);
                    //spreadsheetConversion.addRow(sheetName, rowData, firstRow);

        }
        return spreadsheetConversion;
    }
}
