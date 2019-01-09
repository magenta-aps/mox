/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


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
