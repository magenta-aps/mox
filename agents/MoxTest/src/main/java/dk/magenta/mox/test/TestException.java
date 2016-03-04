package dk.magenta.mox.test;

/**
 * Created by lars on 04-03-16.
 */
public class TestException extends Exception {
    public TestException() {}
    public TestException(Throwable cause) {
        super(cause);
    }
    public TestException(String message) {
        super(message);
    }
}
