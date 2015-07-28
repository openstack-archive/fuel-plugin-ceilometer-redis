
Installation Guide
==================

Building the plugin
-------------------

To build Ceilometer Redis plugin:

#. Clone the fuel-plugin repo:

    ``git clone https://review.openstack.org/openstack/fuel-plugin-ceilometer-redis``

#. Install the Fuel Plugin Builder:

    ``pip install fuel-plugin-builder``

#. Build Ceilometer Redis Fuel plugin:

   ``fpb --build fuel-plugin-ceilometer-redis/``

#. The ceilometer-redis-<x.x.x>.fp plugin package will be created in the plugin folder
   (fuel-plugin-ceilometer-redis/).


Install the Plugin
------------------

To install the Redis plugin:

#. Move the built file to the Fuel Master node with secure copy (scp):

   ``scp fuel-plugin-ceilometer-redis/ceilometer-redis-<x.x.x>.fp root@:<the_Fuel_Master_node_IP address>:/tmp``
   ``ssh root@:<the_Fuel_Master_node_IP address>``
   ``cd /tmp``

#. Install the Ceilometer Redis plugin:

   ``fuel plugins --install ceilometer-redis-<x.x.x>.fp``


#. Verify that the plugin is installed correctly:
   ::

     [root@fuel-master ~]# fuel plugins list
     id | name             | version | package_version
     ---|------------------|---------|----------------
     4  | ceilometer-redis | 1.0.0   | 2.0.0


Deployment details
------------------

* Plugin changes deployment of Ceilometer central agent:
  Now every controller has his own running ceilometer central service
  which are joined into coorditation group. These changes in deployment
  will be done automatically

* Plugin configures redis-server under pacemaker to monitor its process

* Plugin configures redis-sentinel to monitor the state of redis cluster,
  to elect new master during failovers, to forward ceilometer agents
  to new elected redis master, to organize sync between redis nodes.
