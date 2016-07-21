package dk.magenta.mox.moxtabel;

import dk.magenta.mox.json.JSONArray;

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
