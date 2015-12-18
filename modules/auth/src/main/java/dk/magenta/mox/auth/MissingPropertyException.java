package dk.magenta.mox.auth;

/**
 * Created by lars on 06-10-15.
 */
public class MissingPropertyException extends Exception {
    public MissingPropertyException(String propertyKey) {
        super("Missing required property key '"+propertyKey+"'.");
    }
}
