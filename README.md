Ceilometer Redis plugin
=======================

Provide a mechanism to allow the central agent to be horizontally scaled out,
such that each agent polls a disjoint subset of resources.

Redis was chosen as coordination backend for Fuel deployments with Ceilometer.

This repository contains all necessary files to build Ceilometer Redis Fuel plugin.
Currently, the only supported Fuel version is 7.0 (Ubuntu deployments).

Building the plugin
-------------------

1. Clone the fuel-plugin repo from:

    ``git clone https://github.com/stackforge/fuel-plugin-ceilometer-redis``

2. Install the Fuel Plugin Builder:

    ``pip install fuel-plugin-builder``

3. Build Ceilometer Redis Fuel plugin:

   ``fpb --build fuel-plugin-ceilometer-redis/``

4. The ceilometer-redis-<x.x.x>.fp plugin package will be created in the plugin folder
   (fuel-plugin-ceilometer-redis/).

5. Move this file to the Fuel Master node with secure copy (scp):

   ``scp fuel-plugin-ceilometer-redis/ceilometer-redis-<x.x.x>.fp root@:<the_Fuel_Master_node_IP address>:/tmp``
   ``ssh root@:<the_Fuel_Master_node_IP address>``
   ``cd /tmp``

6. Install the Ceilometer Redis plugin:

   ``fuel plugins --install ceilometer-redis-<x.x.x>.fp``

7. Plugin is ready to use and can be enabled on the Settings tab of the Fuel web UI.


Deployment details
------------------

* Plugin changes deployment of Ceilometer central agent:
  Now every controller has his own running ceilometer central service
  which are joined in coorditation group.

* Plugin configures redis-server under pacemaker to monitor its process

* Plugin configure redis-sentinel to monitor the state of redis cluster,
  to elect new master during failovers, to forward ceilometer agents
  to new elected redis master, to organize sync between redis nodes.


Accessing Workload partitioning functionality
---------------------------------------------

Please use official Openstack documentation to obtain more information:
- http://specs.openstack.org/openstack/ceilometer-specs/specs/juno/central-agent-partitioning.html
