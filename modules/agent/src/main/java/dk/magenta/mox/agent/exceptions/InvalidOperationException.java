package dk.magenta.mox.agent.exceptions;

/**
 * Created by lars on 06-10-15.
 */
public class InvalidOperationException extends Exception {
    public InvalidOperationException(String operation) {
        super("Operation '"+operation+"' does not exist.");
    }
}
