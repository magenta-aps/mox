/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.moxtabel;

import dk.magenta.mox.agent.json.JSONArray;

import java.util.ArrayList;

/**
 * Created by lars on 20-06-16.
 */
public class StructurePath extends ArrayList<String> {

    public StructurePath() {
        super();
    }

    public StructurePath(JSONArray array) {
        this();
        for (int i = 0; i < array.length(); i++) {
            this.add(array.getString(i));
        }
    }

    public StructurePath subPath(int endIndex) {
        StructurePath sub = new StructurePath();
        if (endIndex < 0) {
            endIndex = this.size() + endIndex;
        } else if (endIndex >= this.size()) {
            endIndex = this.size() - 1;
        }
        for (int i=0; i<=endIndex; i++) {
            sub.add(this.get(i));
        }
        return sub;
    }
}
