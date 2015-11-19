
Installation Guide
==================

Install the Plugin
------------------

To install the Redis plugin:

#. Download the Redis plugin from the
   `Fuel Plugins Catalog <https://www.mirantis.com/products/openstack-drivers-and-plugins/fuel-plugins/>`_.

#. Move the plugin's rpm to the
   `Fuel Master node <https://docs.mirantis.com/openstack/fuel/fuel-7.0/quickstart-guide.html#quickstart-guide>`_ with secure copy (scp)::

        scp fuel-plugin-ceilometer-redis/ceilometer-redis-1.0-1.0.0-1.noarch.rpm /
        root@:<the_Fuel_Master_node_IP address>:/tmp


#. Log into the Fuel Master node and install the Ceilometer Redis plugin::

          ssh root@:<the_Fuel_Master_node_IP address>
          cd /tmp
          fuel plugins --install ceilometer-redis-1.0-1.0.0-1.noarch.rpm


#. Verify that the plugin is installed correctly::

     [root@fuel-master ~]# fuel plugins list
     id | name             | version       | package_version
     ---|------------------|---------------|----------------
     4  | ceilometer-redis | 1.0-1.0.0-1   | 2.0.0



