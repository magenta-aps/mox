package dk.magenta.mox.test;

import org.apache.log4j.Logger;
import org.apache.log4j.xml.DOMConfigurator;

public class MoxTest {

    private Logger log = Logger.getLogger(MoxTest.class);

    public static void main(String[] args) {
        DOMConfigurator.configure("log4j.xml");
    }
}
