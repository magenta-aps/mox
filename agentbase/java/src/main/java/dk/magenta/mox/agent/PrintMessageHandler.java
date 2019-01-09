/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent;

import dk.magenta.mox.agent.json.JSONObject;
import dk.magenta.mox.agent.messages.Headers;

import java.util.concurrent.Future;

/**
 * Created by lars on 04-08-15.
 */
public class PrintMessageHandler implements MessageHandler {

    public Future<String> run(Headers headers, JSONObject jsonObject) {
        System.out.println("-------- Message received --------");
        System.out.println("headers:");
        if (headers == null || headers.isEmpty()) {
            System.out.println("    <none>");
        } else {
            for (String key : headers.keySet()) {
                System.out.println("    " + key + " = " + headers.get(key));
            }
        }
        System.out.println("body:");
        System.out.println(jsonObject.toString(2));
        return new ImmediateFuture<String>("");
    }
}
