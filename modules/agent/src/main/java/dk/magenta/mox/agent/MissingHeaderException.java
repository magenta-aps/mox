package dk.magenta.mox.agent;

/**
 * Created by lars on 06-10-15.
 */
public class MissingHeaderException extends Exception {
    public MissingHeaderException(String headerName) {
        super("Required amqp header '"+headerName+"' not found.");
    }
}
