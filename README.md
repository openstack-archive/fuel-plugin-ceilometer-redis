Ceilometer Redis plugin
=======================

Provides a mechanism to allow Ceilometer agents to be horizontally scaled out
and to balance workload between corresponding agents. The current plugin version
provides this mechanism *only* for Central agent.

Building the plugin
-------------------

1. Clone the fuel-plugin repo:

    ``git clone https://review.openstack.org/openstack/fuel-plugin-ceilometer-redis``

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

7. Plugin is ready to be used and can be enabled on the Settings tab of the Fuel web UI.

