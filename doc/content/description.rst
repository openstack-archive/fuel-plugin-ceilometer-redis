Ceilometer Redis plugin
=======================

Ceilometer Redis Plugin provides a coordination mechanism for
`Ceilometer agents <https://ceilometer.readthedocs.org/en/latest/architecture.html>`_.
The first version of plugin will support only `Central Agent <https://ceilometer.readthedocs.org/en/latest/glossary.html#term-central-agent>`_.
It uses `tooz library <http://docs.openstack.org/developer/tooz/>`_ with
`Redis backend <http://redis.io>`_ to provide a set of resources
to be polled for each Central agent. The plugin also changes deployment of Ceilometer central agent:
now every controller has its own running ceilometer central service
which are joined into coordination group. These changes in deployment will be done automatically.
It also configures redis-server under pacemaker to monitor its process. The plugin configures
`redis-sentinel <http://redis.io/topics/sentinel>`_ to monitor the state of redis cluster,
to elect new master during failovers, to forward ceilometer agents to new elected redis master, to organize sync between redis nodes.


Requirements
------------

======================= ================
Requirement             Version/Comment
======================= ================
Fuel                    7.0
tooz                    <0.14.0,>=0.13.1
======================= ================

Limitations
-----------

* The plugin version 1.0-1.0.0-1 provides coordination only for Agent Central service.
  Alarm evaluator and Notification agent will be supported in the next plugin
  version.

.. include:: installation.rst
.. include:: guide.rst

* The plugin works correctly only on clouds with odd numbers of controllers.
  This requirement is mandatory because Redis needs an odd number of nodes to
  choose the master successfully.
