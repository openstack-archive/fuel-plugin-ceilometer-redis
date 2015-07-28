Ceilometer Redis Plugin User Guide
==================================

Once the Ceilometer Redis plugin plugin has been installed (following `Installation Guide`_), you can
create *OpenStack* environments with Ceilometer whose Central agent works in workload_partitioned mode.

Ceilometer installation
-----------------------

This plugin was created to provide partitioning for Ceilometer services. So its
usage is senseless without Ceilometer installed.
Please, refer to this guide `related projects <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#related-projects>`_
to obtain the information about Ceilometer installation.


Plugin activation
-----------------

#. First of all, make sure that plugin was successfully installed.
  Go to *Plugins* tab. You should see the following:

  .. image:: images/redis-plugin.png
   :width: 100%

#. The next step is activate a plugin. Go to *Environments* tab and
  switch on a checkbox *Redis plugin for Ceilometer*:

  .. image:: images/redis-plugin-on.png
   :width: 100%


Finish environment configuration
--------------------------------

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#verify-networks>`_

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#deploy-changes>`_ to once you are done with environment configuration.