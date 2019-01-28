/*
Copyright (C) 2015-2019 Magenta ApS, https://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent;

import dk.magenta.mox.agent.json.JSONObject;

import java.util.concurrent.Future;

/**
 * Created by lars on 23-09-15.
 */
public abstract class Util {

    public static String error(Exception e) {
        JSONObject errorObject = new JSONObject();
        errorObject.put("type", e.getClass().getSimpleName());
        errorObject.put("message", e.getMessage());
        errorObject.put("sourceProgram", "Mox agent listener");
        return errorObject.toString();
    }

    public static Future<String> futureError(Exception e) {
        return new ImmediateFuture<>(Util.error(e));
    }
}
