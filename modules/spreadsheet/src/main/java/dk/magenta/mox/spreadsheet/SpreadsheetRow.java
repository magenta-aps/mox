package dk.magenta.mox.spreadsheet;

import java.util.ArrayList;

/**
 * Created by lars on 27-11-15.
 */
public class SpreadsheetRow extends ArrayList<String> {

    public boolean isEmpty() {
        if (!super.isEmpty()) {
            for (String s : this) {
                if (s != null && !s.isEmpty()) {
                    return false;
                }
            }
        }
        return true;
    }

}
