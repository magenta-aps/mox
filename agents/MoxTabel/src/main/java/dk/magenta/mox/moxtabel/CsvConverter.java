/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


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
