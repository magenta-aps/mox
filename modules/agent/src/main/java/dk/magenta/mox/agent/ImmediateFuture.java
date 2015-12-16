package dk.magenta.mox.agent;

import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * Created by lars on 04-08-15.
 */
public class ImmediateFuture<V> implements Future<V> {

    private V value;
    public ImmediateFuture(V value) {
        this.value = value;
    }

    public boolean cancel(boolean mayInterruptIfRunning) {
        return false;
    }

    public boolean isCancelled() {
        return false;
    }

    public boolean isDone() {
        return true;
    }

    public V get() throws InterruptedException, ExecutionException {
        return this.value;
    }

    public V get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException {
        return this.value;
    }
}
