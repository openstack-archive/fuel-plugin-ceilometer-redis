..
 This work is licensed under a Creative Commons Attribution 3.0 Unported
 License.

 http://creativecommons.org/licenses/by/3.0/legalcode

==============================================
Add central agent HA and workload partitioning
==============================================

https://blueprints.launchpad.net/fuel/+spec/ceilometer-central-agent-ha

Implement Redis installation and using it as a coordination backend
for ceilometer central agents

Problem description
===================

A detailed description of the problem:

* Currently there are several Ceilometer services which do not support workload
  partitioning in MOS: central agent, alarm evaluator and agent notification. During
  Juno release cycle workload partitioning for central agent was implemented.
  In Kilo, partition coordination was introduced to alarm evaluator and agent
  notification. In Liberty, coordination for notification agent was further improved.
  Thus, it should be supported in MOS.
  For this purpose we should provide tooz library support. This library is responsible for
  coordination between services and supports several backends: zookeeper, redis, memcached.
  Redis was chosen as the tooz backend in MOS.

Proposed change
===============

Support for Ceilometer services coordination is an experimental feature and it was
decided to implement it as a fuel plugin.

Its implementation requires the following things to be done:
* Implement Redis installation on controller nodes in HA mode
* Prepare Redis packages and their dependencies
* Enable partitioning in config for ceilometer central agents
* Enable partitioning in config for ceilometer  alarm evaluator
* Enable partitioning in config for ceilometer notification agents

Installation diagram for central agent is below. The schemas for alarm-evaluator and
notification agent are similar

::

 +---------------------+
 |                     |
 |  +---------------+  |
 |  |  ceilometer   +-------------------------+
 |  | central agent |  |                      |
 |  +---------------+  |                      |
 |                     |                      |
 |  Primary controller |                      |
 |                     |                      |
 |  +---------------+  |                      |
 |  |     redis     <------------------------------+
 |  |     master    |  |                      |    |
 |  +---------------+  |                      |    |
 |                     |                      |    |
 +---------------------+                      |    |
                                              |    |
 +---------------------+                      |    |
 |                     |                      |    |
 |  +---------------+  |                      |    |
 |  |  ceilometer   +-------------------------+    |
 |  | central agent |  |                      |    |
 |  +---------------+  |                      |    |
 |                     |               +------v----+--+
 |     controller 1    |               |              |
 |                     |               | Coordination |
 |  +---------------+  |               |              |
 |  |     redis     |  |               +------^----+--+
 |  |     slave1    |  |                      |    |
 |  |               <------------------------------+
 |  +---------------+  |                      |    |
 |                     |                      |    |
 +---------------------+                      |    |
                                              |    |
 +---------------------+                      |    |
 |                     |                      |    |
 |  +---------------+  |                      |    |
 |  |  ceilometer   +-------------------------+    |
 |  | central agent |  |                           |
 |  +---------------+  |                           |
 |                     |                           |
 |     controller 2    |                           |
 |                     |                           |
 |  +---------------+  |                           |
 |  |     redis     |  |                           |
 |  |     slave2    <------------------------------+
 |  |               |  |
 |  +---------------+  |
 |                     |
 +---------------------+


Alternatives
------------

* We may use MQ queues for task ditribution between the services. The problem is
  that MQ is one of the most weak point in OpenStack now and it may be not safe
  to make it responsible for HA and coordination.

Data model impact
-----------------

None

REST API impact
---------------

None

Upgrade impact
--------------

These changes will be needed in puppet scripts:

* Add redis module

* Configure ceilometer agents to be partitioned


This change will be needed in packages:

* Use upstream Redis packages and its dependencies

Security impact
---------------

None

Notifications impact
--------------------

None

Other end user impact
---------------------

None

Performance Impact
------------------

Performance should become better because the same amount of work will be
done using several workers

Other deployer impact
---------------------

This could be installed only in HA mode with ceilometer

Developer impact
----------------

None

Implementation
==============

Assignee(s)
-----------

Primary assignee:
  Ivan Berezovskiy

Other contributors:
  Nadya Shakhat, Ilya Tyaptin, Igor Degtiarov

Reviewer:
  Vladimir Kuklin Sergii Golovatiuk

QA:
  Vitaly Gusev

Work Items
----------

* Implement redis installation from puppet (iberezovskiy)

* Configure ceilometer central agent (iberezovskiy)

* Configure alarm evaluator (Nadya Shakhat)

* Configure notification agents (Nadya Shakhat)

* Write a documentation (Nadya Shakhat)

Dependencies
============

None

Testing
=======

General testing approach:

* Environment with ceilometer in HA mode should be successfully deployed

* Redis cluster should be with one master and two slaves

* Ensure that after node with redis master was broken ceilometer services
  can work with new redis master


Testing approach for central agent:

* Ceilometer should collect all enabled polling meters for deployed
  environment

* Ensure that the sets of meters to be polled by each central agent are disjoint

* Ensure that after one central agent is broken, during the next polling
  cycle all measurements will be rescheduled between two another,
  and all of meters will be collected


Testing approach for alarm evaluator:

* Ensure that alarms can be successfully created

* Ensure that after one alarm evaluator is broken, during the next alarm evaluation
  cycle all alarms will be rescheduled between two another for further evaluation
  and all of alarms will be successfully evaluated

* Ensure that the sets of alarms for each alarm evaluator are disjoint


Testing approach for notification agent:

* Ensure that messages don't not stuck in notification.info queue

* Ensure that IPC queues are created in MQ, chech that list of IPC queues corresponds
  to pipeline.yaml and each queue has the one consumer

* Ensure that after one alarm evaluator was broken, during the next alarm evaluation
  cycle all alarms will be rescheduled between two another for further evaluation
  and all of them will be successfully evaluated

Documentation Impact
====================

A Plugin Guide about redis plugin installation should be created.
Also, the document about ceilometer HA and partitioning should be done.

For validation and testing purpose, the test plan and test report should be provided.

References
==========

1. Central agent: https://github.com/openstack/ceilometer-specs/blob/master/specs/juno/central-agent-partitioning.rst
2. Notification agent: https://github.com/openstack/ceilometer-specs/blob/master/specs/kilo/notification-coordiation.rst
3. Notification agent cont.: https://github.com/openstack/ceilometer-specs/blob/master/specs/liberty/distributed-coordinated-notifications.rst
