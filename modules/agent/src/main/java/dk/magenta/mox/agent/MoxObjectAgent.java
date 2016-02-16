package dk.magenta.mox.agent;

import java.util.Map;

/**
 * Created by lars on 15-02-16.
 */
public class MoxObjectAgent extends MoxAgent {

    private Map<String, ObjectType> objectTypes;

    public MoxObjectAgent(String[] args) {
        super(args);
        this.objectTypes = ObjectType.load(this.properties);
    }
}
