/*
Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.moxtabel;

import java.util.ArrayList;
import java.util.HashMap;

/**
 * Created by lars on 27-11-15.
 */
public class SpreadsheetRow extends ArrayList<String> {

    public SpreadsheetRow() {
        super();
    }
    public SpreadsheetRow(int capacity) {
        super(capacity);
    }

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

    public HashMap<String, String> toMap(SpreadsheetRow headerRow) {
        HashMap<String, String> map = new HashMap<>();
        int columns = Math.min(this.size(), headerRow.size());
        for (int i=0; i<columns; i++) {
            map.put(headerRow.get(i), this.get(i));
        }
        return map;
    }


}
