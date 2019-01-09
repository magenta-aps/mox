/*
Copyright (C) 2015-2019 Magenta ApS, http://magenta.dk.
Contact: info@magenta.dk.

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
*/


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
