Ceilometer Redis plugin
=======================

Ceilometer Redis Plugin provides a coordination mechanism for Ceilometer
agents. The first version of plugin will support only Central Agent.
It uses tooz library with Redis backend to provide a set of resources
to be polled for each Central agent.


Requirements
------------

======================= ================
Requirement             Version/Comment
======================= ================
Fuel                    7.0
ceilometer-redis        1.0.0
tooz                    <0.14.0,>=0.13.1
======================= ================

Limitations
-----------

* The plugin version 1.0.0 provides coordination only for Agent Central service.
  Alarm evaluator and Notification agent will be supported in the next plugin
  version.