/*
Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent;

import dk.magenta.mox.agent.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Created by lars on 04-08-15.
 */
public class DummyMessageGenerator implements MessageGenerator<JSONObject> {

    private ArrayList<JSONObject> generatedNotifications = new ArrayList<JSONObject>();
    private Thread generatorThread = null;

    public DummyMessageGenerator() {
        this.generatorThread = new Thread(new Runnable() {
            public void run() {
                try {
                    while (true) {
                        Thread.sleep(5000);
                        JSONObject notification = new JSONObject();
                        notification.put("notificationId", UUID.randomUUID().toString());
                        DummyMessageGenerator.this.generatedNotifications.add(notification);
                        System.out.println("Notification generated");
                    }
                } catch (InterruptedException e) {
                }
            }
        });
        this.generatorThread.start();
    }


    public List<JSONObject> getNotifications() {
        while (this.generatedNotifications.isEmpty()) {
            try {
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
        List<JSONObject> notifications = new ArrayList<JSONObject>(this.generatedNotifications);
        this.generatedNotifications.clear();
        return notifications;
    }

    public boolean isRunning() {
        return generatorThread != null;
    }

    public void stop() {
        if (this.generatorThread != null) {
            this.generatorThread.interrupt();
            this.generatorThread = null;
        }
    }
};
