/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


package dk.magenta.mox.agent;

import java.util.concurrent.Future;

import dk.magenta.mox.agent.json.JSONObject;
import dk.magenta.mox.agent.messages.Headers;

public interface MessageHandler {
    Future<String> run(Headers headers, JSONObject jsonObject);
}
