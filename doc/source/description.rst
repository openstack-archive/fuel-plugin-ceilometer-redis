Ceilometer Redis plugin
=======================

The Ceilometer Redis Plugin is used to install `Redis <http://redis.io>`_ in a
Mirantis OpenStack (MOS) environment. The plugin provides coordination mechanisms,
through the use of the `tooz library <http://docs.openstack.org/developer/tooz/>`_,
to enable the horizontal scaling of the
`Ceilometer Agents <https://ceilometer.readthedocs.org/en/latest/architecture.html>`_
and Alarm Evaluators. In its current version, the plugin enables horizontal
scaling for the following Ceilometer services:

  * The Central Agent
  * The Alarm Evaluator

Each of these services are running on all the controllers after the plugin is installed.
All of them are joined into the corresponding coordination group (one coordination group per service).
This differs from the default configuration when there is only one Central Agent and
one Alarm Evaluator per MOS environment.
The plugin also configures *redis-server* under Pacemaker to monitor its process.
The plugin configures `redis-sentinel <http://redis.io/topics/sentinel>`_ to:

  * Monitor the state of the Redis cluster
  * Elect a new master during a failover
  * Forward the Ceilometer services to the elected Redis master
  * Organize the synchronization between Redis nodes.

Central Agent
-------------
The Central Agent is responsible for polling all the OpenStack resources
excepted those of Nova, like the VMs, which are polled by the Compute Agent.
Without coordination, there can be only one Central Agent running at a time.
This is because by default, the Central Agent works on the entire resources set.
Running multiple Central Agents without coordination would poll the entire
resources set as many times as the number of Central Agents running every polling
interval. This is not how to scale the Central Agent functions.
Thus, coordination allows to create shards of disjoint resources sets
to distribute the polling workload across multiple Central Agents.  

Alarm evaluator
---------------
The Ceilometer Alarm Evaluator service is responsible for Ceilometer alarms evaluation.
By default, in MOS there is only one Alarm Evaluator per environment.
The reason is the same as for the Central Agent.
If there are several Alarm Evaluators and no coordination enabled,
then all the Alarm Evaluators will evaluate the same set of alarms
every configurable time interval.
Thus, coordination allows to create shards of disjoint alarms sets
to distribute the alarms evaluation workload across multiple Alarm Evaluators. 

Requirements
------------

======================= ================
Requirement             Version/Comment
======================= ================
Fuel                    7.0, 8.0
tooz                    <0.14.0,>=0.13.1
======================= ================

.. _limitations:

Limitations
-----------

* The plugin works correctly only in environments with an odd number of controllers.
  This requirement is mandatory because Redis needs an odd number of nodes to be
  able to elect a master.

* Before Liberty, there was no need to coordinate Ceilometer Notification Agents. Starting from Liberty, samples
  transformations started to be handled not by compute/central agents as it was before, but by a notification agent.
  Some of Ceilometer transformers have a local cache where they store the data from the previously processed samples.
  For example, "cpu_util" metric are obtained from two consecutive Samples with "cpu" metric: one is subtracted from
  another and divided by an amount of cpu (this information is stored in Sample's metadata).
  Thus, it should be guaranteed that all the Samples which should be transformed by one transformer, will go to the
  same notification agent. If some of the samples go to another, the cache cannot be shared and some data will be lost.

  To handle this process properly, IPC queues was introduced  - inter process communication queues in message bus
  (RabbitMQ). With coordination enabled, each notification agent has two set of listeners: for main queues and for IPC
  queues. All notification agents listen to _all_ the main queues (where we have all messages from OpenStack services
  and polling-based messages from central/compute agents) and re-publish messages to _all_ IPC queues. Coordination
  starts to work at this point: every notification agent in the cloud has it's own set of IPC queues to listen to. Thus,
  we can be sure that local cache on each notification agent contains all the previous data required for transformation.

  After some investigations, some performance issues were found with IPC approach. That's why in In MOS 8.0 all basic
  transformations (cpu_util, disk.read.requests.rate, disk.write.requests.rate, disk.read.bytes.rate, disk.write.bytes.rate,
  disk.device.read.requests.rate, disk.device.read.bytes.rate, disk.device.write.bytes.rate, network.incoming.bytes.rate,
  network.outgoing.bytes.rate, network.incoming.packets.rate, network.outgoing.packets.rate) were moved back to compute
  nodes, i.e. for the basic set of transformations there is no need to run notification agent in coordination mode.
  That's the reason why the plugin does't support coordination for notification agents, although it is possible to configure
  notification agents to run in coordination mode manually. Anyway, it is not recommended.

  If you have any custom transformers, you need to be sure that they are cache-less, i.e. are based only on
  ``unit_conversion`` transformer or the ``arithmetic`` transformer. If it's not the case, you may consider the following
  options: run only one notification agent in the cloud or install this plugin and do all configuration manually.


