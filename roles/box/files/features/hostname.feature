# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

Feature: Testing if the hostname is correct

  Scenario: Hostname is set correctly
    Given both the node and the configuration language are defined
     When we execute the command "sh run | in hostname"
     Then we see the hostname set correctly