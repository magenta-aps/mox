package dk.magenta.mox.agent.exceptions;

/**
 * Created by lars on 06-10-15.
 */
public class InvalidObjectTypeException extends Exception {
    public InvalidObjectTypeException(String objectType) {
        super("Object type '"+objectType+"' does not exist.");
    }
}
