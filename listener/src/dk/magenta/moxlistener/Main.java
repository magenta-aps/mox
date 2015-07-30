package dk.magenta.moxlistener;

import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 30-07-15.
 */
public class Main {
    public static void main(String[] args) throws IOException, TimeoutException {
        MessageReceiver test = new MessageReceiver("localhost", "incoming");
        try {
            test.run(new MessageHandler("http", "127.0.0.1", 5000));
        } catch (InterruptedException e) {
            e.printStackTrace();
        }


        test.close();
    }
}
