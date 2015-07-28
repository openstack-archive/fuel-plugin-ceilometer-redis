
Installation Guide
==================

Install the Plugin
------------------

To install the Redis plugin:

#. Move the built file to the
   `Fuel Master node <https://docs.mirantis.com/openstack/fuel/fuel-7.0/quickstart-guide.html#quickstart-guide>`_ with secure copy (scp)::

        scp fuel-plugin-ceilometer-redis/ceilometer-redis-<x.x.x>.fp /
        root@:<the_Fuel_Master_node_IP address>:/tmp


#. Log into the Fuel Master node and install the Ceilometer Redis plugin::

          ssh root@:<the_Fuel_Master_node_IP address>
          cd /tmp
          fuel plugins --install ceilometer-redis-<x.x.x>.fp


#. Verify that the plugin is installed correctly::

     [root@fuel-master ~]# fuel plugins list
     id | name             | version | package_version
     ---|------------------|---------|----------------
     4  | ceilometer-redis | 1.0.0   | 2.0.0



