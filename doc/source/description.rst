Ceilometer Redis plugin
=======================

Ceilometer Redis Plugin aims to install Redis to MOS environment and provide a coordination mechanism for
`Ceilometer agents <https://ceilometer.readthedocs.org/en/latest/architecture.html>`_ and Alarm Evaluator
through the `tooz library <http://docs.openstack.org/developer/tooz/>`_ with a `Redis backend <http://redis.io>`_
The plugin supports coordination for the following Ceilometer services: central agent and alarm-evaluator.
Each of these services are running on every controller after the plugin is installed. All of them are joined
into the corresponding coordination group (one coordination group per each service). It differs from the default
configuration when there should be only one central agent and alarm-evaluator per cloud. The plugin also configures
redis-server under pacemaker to monitor its process. The plugin configures `redis-sentinel <http://redis.io/topics/sentinel>`_
to monitor the state of the redis cluster, to elect new master during failovers, to forward ceilometer services to new
elected redis master, to organize sync between redis nodes.


Central agent
-------------
Ceilometer Central agent is responsible for polling all OpenStack resources except Nova's (Nova resources,
i.e. vms, are polled by a Compute agent). Without coordination enabled, only one Central agent should be running
per cloud. The reason is that all the central agents have the same set of OpenStack resources to poll every
configurable time interval. If coordination is not enabled, each OpenStack resource will be polled as many times
as many instances of Central agents are running in a cloud.
Thus, coordination provides a disjoint set of OpenStack resources to poll for every Central agent running on the
cloud to avoid polling one resource several times.

Alarm evaluator
---------------
Ceilometer alarm evaluator service is responsible for Ceilometer alarm evaluation.
By default, in MOS there is only one alarm evaluator per cloud. The reason is the same as for a central agent.
If there are several alarm evaluators and no coordination enabled, all of them will evaluate the same set of alarms
every configurable time interval. The alarm sets for evaluators should be disjoint. So, coordination is responsible
for providing the set of alarms to evaluate to each alarm-evaluator in the cloud.


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

* The plugin works correctly only on clouds with odd numbers of controllers.
  This requirement is mandatory because Redis needs an odd number of nodes to
  choose the master successfully.

* Before Liberty, there was no need to coordinate Ceilometer notification agents. Starting from Liberty, samples
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


