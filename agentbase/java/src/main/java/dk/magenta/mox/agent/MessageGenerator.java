package dk.magenta.mox.agent;

import java.util.List;

/**
 * Created by lars on 04-08-15.
 */
public interface MessageGenerator<V> {
    public List<V> getNotifications();
    public boolean isRunning();
    public void stop();
}
