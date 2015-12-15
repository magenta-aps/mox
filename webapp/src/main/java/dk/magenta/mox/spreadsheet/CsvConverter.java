package dk.magenta.mox.spreadsheet;

import dk.magenta.mox.agent.ObjectType;
import org.odftoolkit.simple.SpreadsheetDocument;
import org.odftoolkit.simple.table.Cell;
import org.odftoolkit.simple.table.Row;
import org.odftoolkit.simple.table.Table;

import java.io.IOException;
import java.io.InputStream;
import java.util.Map;
import java.util.Scanner;

/**
 * Created by lars on 26-11-15.
 */
public class CsvConverter extends SpreadsheetConverter {

    protected CsvConverter(Map<String, ObjectType> objectTypes) throws IOException {
        super(objectTypes);
    }

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
