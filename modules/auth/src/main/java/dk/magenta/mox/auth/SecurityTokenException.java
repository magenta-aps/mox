package dk.magenta.mox.auth;

import org.apache.axis2.AxisFault;
import org.apache.commons.httpclient.ConnectTimeoutException;
import org.apache.rahas.TrustException;

import javax.xml.stream.XMLStreamException;
import java.io.FileNotFoundException;
import java.net.URISyntaxException;

/**
 * Created by lars on 03-12-15.
 */
public class SecurityTokenException extends Exception {

    private Exception cause;
    public SecurityTokenException(AxisFault axisFault) {
        super("Got an AxisFault when communicating with Identity Service: " + axisFault.getMessage());
        this.cause = axisFault;
    }

    public SecurityTokenException(TrustException trustException) {
        super("Failed authenticating to Identity Service: " + trustException.getMessage());
        this.cause = trustException;
    }

    public SecurityTokenException(XMLStreamException xmlStreamException) {
        super("Got an XMLStreamException when communicating with Identity Service: " + xmlStreamException.getMessage());
        this.cause = xmlStreamException;
    }

    public SecurityTokenException(URISyntaxException uriSyntaxException) {
        super("Incorrectly formatted URI: " + uriSyntaxException.getMessage());
        this.cause = uriSyntaxException;
    }

    public SecurityTokenException(FileNotFoundException fileNotFoundException) {
        super("Couln't find file: " + fileNotFoundException.getMessage());
        this.cause = fileNotFoundException;
    }
    public SecurityTokenException(ConnectTimeoutException connectTimeoutException) {
        super("Couldn't connect to Identity Service: " + connectTimeoutException.getMessage());
        this.cause = connectTimeoutException;
    }

    public Exception getCause() {
        return this.cause;
    }
}
