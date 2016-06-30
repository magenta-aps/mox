package dk.magenta.mox.agent;

import java.util.concurrent.ArrayBlockingQueue;

/**
 * Created by lars on 14-06-16.
 */
public class Throttle {
    int executionCount;
    ArrayBlockingQueue<String> queue;

    public Throttle(int executionCount) {
        this.executionCount = executionCount;
        if (executionCount > 0) {
            this.queue = new ArrayBlockingQueue<String>(executionCount);
        }
    }

    public boolean willWait() {
        if (this.queue == null) {
            return false;
        } else {
            return this.queue.remainingCapacity() > 0;
        }
    }

    public void waitForIdle() throws InterruptedException {
        if (this.queue != null) {
            this.queue.put(""); // Blocks if the queue is full
        }
    }

    public void yield() {
        if (this.queue != null) {
            this.queue.poll(); // Takes one from the queue (doesn't block)
        }
    }

}
