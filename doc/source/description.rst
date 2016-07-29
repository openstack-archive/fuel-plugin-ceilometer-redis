Overview
========

The *Ceilometer Redis Plugin* installs `Redis <http://redis.io>`_ and
the `Tooz library <http://docs.openstack.org/developer/tooz/>`_, in a
Mirantis OpenStack (MOS) environment deployed by Fuel.
Both Redis and the Tooz library should be installed on all the controller
nodes of the environment. Starting from MOS 9.0, Ceilometer alarming service was
moved to the project called Aodh.


The *Ceilometer Redis Plugin* is used to provide coordination mechanisms to
enable the horizontal scaling of the Ceilometer/Aodh services. Using the plugin,
the Ceilometer/Aodh services are joined into a so-called **coordination group**,
which allows for resources and alarms sharding.
There is one coordination group per service type.

Please refer to the `Telemetry architecture
<http://docs.openstack.org/admin-guide/telemetry-system-architecture.html>`_
documentation for more information about the Ceilometer services.

In MOS 9.0, the *Ceilometer Redis Plugin* enables coordination
for both:

  * The **ceilometer-agent-central service**.

    The ceilometer-agent-central service is responsible for polling all the OpenStack resources,
    excepted those of Nova, like the VM instances, that are polled by the **ceilometer-agent-compute**.
    Without coordination, there can be only one ceilometer-agent-central running at a time.
    This is because, by default, the ceilometer-agent-central works with an entire set of resources.
    As such, running multiple ceilometer-agent-central without coordination would poll the entire
    set of resources as many times as the number of agents running on the controller nodes every
    polling interval. This is obviously not a proper way to scale out the ceilometer-agent-central.
    To cope with this problem, the coordination mechanism provided
    by the *Ceilometer Redis Plugin* allows distributing the polling workload
    across multiple instances of the ceilometer-agent-central using disjoint sets
    of resources.

  * The **aodh-evaluator service**.

    The **aodh-evaluator** service is responsible for evaluating the Ceilometer alarms.
    By default, there is only one aodh-evaluator running per environment.
    Without coordination, there can be only one aodh-evaluator running at a time.
    This is because, as for the ceilometer-agent-central, the aodh-evaluator works
    with an entire set of alarms. Running multiple aodh-evaluator
    without coordination would evaluate all the alarms as many times as the number of evaluators
    running on the controller nodes every evaluation interval. To cope with this problem,
    the coordination mechanism provided by the *Ceilometer Redis Plugin* allows distributing
    the alarms evaluation workload across multiple instances of the aodh-evaluator
    using disjoint sets of alarms.

Please note that starting from MOS 8.0, the *Ceilometer Redis Plugin* doesn't provide support
(out-of-the-box) for the coordination of the **ceilometer-agent-notification** service because
it is not needed for the most common samples transformations.

.. note:: Before Liberty, the transformation of the samples was handled by the
   **ceilometer-agent-compute** and the **ceilometer-agent-central** services.
   In Liberty, the transformation of the samples was moved
   to the **ceilometer-agent-notification** service, but after thorough performance analysis
   of Ceilometer at scale, we discovered that this change has a bad impact on performance.
   Starting from MOS 8.0, the transformations for the following list of measurements were moved back
   to the ceilometer-agent-compute service.

   * cpu_util
   * disk.read.requests.rate
   * disk.write.requests.rate
   * disk.read.bytes.rate
   * disk.write.bytes.rate
   * disk.device.read.requests.rate
   * disk.device.read.bytes.rate
   * disk.device.write.bytes.rate
   * network.incoming.bytes.rate
   * network.outgoing.bytes.rate
   * network.incoming.packets.rate
   * network.outgoing.packets.rate

   As a result, starting from MOS 8.0, there is no need to run the ceilometer-agent-notification
   in coordination mode unless you need to maintain the transformation of custom samples that
   are not listed above. In this case, it is possible to enable coordination for the
   ceilometer-agent-notification service manually event though, it is not recommended
   for performance reasons.

In addition to the above, the *Ceilometer Redis Plugin* configures *Pacemaker*
and `redis-sentinel <http://redis.io/topics/sentinel>`_
to enable **high availability** of the Redis cluster. Redis clustering includes:

   * Monitoring the state of the **redis-server** processes
   * Elect a new redis-server master during a failover
   * Connect Ceilometer to the elected redis-server
   * Organize the synchronization between Redis nodes

Requirements
------------

======================= ================
Requirements            Version/Comment
======================= ================
MOS                     9.0
Tooz                    >=1.28.0
======================= ================

.. _limitations:

Limitations
-----------

* The *Ceilometer Redis Plugin* requires to install on an odd number of controller
  nodes to work properly. This is because, Redis clustering requires an odd number of nodes
  to avoid the split brain effect when electing a master.

* If you have any custom transformers you need to ensure that they are cache-less.
  If transformation is cache-less, then there is no need to enable the coordination.
  That is, based only on the ``unit_conversion`` transformer or the ``arithmetic`` transformers.
  Otherwise, you will have to consider running only one instance of the ceilometer-agent-notification
  service in your MOS environment or install the *Ceilometer Redis Plugin* and do all the
  configuration manually.
