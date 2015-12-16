package dk.magenta.mox.agent;

import java.util.concurrent.*;

/**
 * Created by lars on 03-08-15.
 *
 * Implementation of java.util.concurrent.Future, that returns a value when the set() method is called.
 *
 * isDone() will return false until set() has been called
 * get() will block until set is called (be careful to do these in separate threads)
 */
public class SettableFuture<V> implements Future<V> {

    private V value;
    private boolean done = false;
    private boolean cancelled = false;
    private CountDownLatch blocker;

    public SettableFuture(){
        this.blocker = new CountDownLatch(1); // Initialize the "counter" at 1
    }

    public boolean cancel(boolean mayInterruptIfRunning) {
        if (this.done) {
            return false;
        }
        this.done = true;
        this.cancelled = true;
        return true;
    }

    public boolean isCancelled() {
        return this.cancelled;
    }

    public boolean isDone() {
        return this.done;
    }

    public V get() throws InterruptedException, ExecutionException {
        if (!this.done) {
            this.blocker.await(); // Block execution until the counter reaches 0
        }
        return this.value;
    }

    public V get(long timeout, TimeUnit unit) throws InterruptedException, ExecutionException, TimeoutException {
        if (!this.done) {
            this.blocker.await(timeout, unit);
        }
        return this.value;
    }

    public boolean set(V value) {
        if (this.done) {
            return false;
        }
        this.value = value;
        this.done = true;
        this.blocker.countDown(); // Decrease the counter by 1
        return true;
    }
}
