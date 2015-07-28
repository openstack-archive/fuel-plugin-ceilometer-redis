User Guide
==========

Once the Ceilometer Redis plugin plugin has been installed (following `Installation Guide`_), you can
create *OpenStack* environments with Ceilometer whose Central agent works in workload_partitioned mode.

Ceilometer installation
-----------------------

This plugin was created to provide partitioning for Ceilometer services. So its
usage is senseless without Ceilometer installed.
So, you will need to `create a new OpenStack environment <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#create-a-new-openstack-environment>`_
with `Ceilometer <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#related-projects>`_ using the Fuel UI Wizard.


Plugin configuration
--------------------

#. First of all, make sure that plugin was successfully installed.
   Go to the *Plugins* tab. You should see the following:

   .. image:: images/redis-plugin.png
    :width: 100%

#. The next step is enable the plugin. Go to *Environments* tab and
   select the *Redis plugin for Ceilometer* checkbox:

   .. image:: images/redis-plugin-on.png
    :width: 100%

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#verify-networks>`_

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#deploy-changes>`_ to once you are done with environment configuration.
