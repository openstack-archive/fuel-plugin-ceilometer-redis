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

#. Run `network verification check <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#verify-networks>`_.

#. Press `Deploy button <https://docs.mirantis.com/openstack/fuel/fuel-7.0/user-guide.html#deploy-changes>`_ to once you are done with environment configuration.


How to check that plugin works
------------------------------
#. Check that ceilometer-agent-central service is running on each controller. Run ``pcs resource``
   and you should see the following in the output::

          Clone Set: clone_p_ceilometer-agent-central [p_ceilometer-agent-central]
            Started: [ node-1.domain.tld node-2.domain.tld node-3.domain.tld ]


   ``Started`` list should contain all controllers.

#. Check that samples are not duplicated. For this purpose you may choose
   any metric collected by central agent. All these metrics may be found here
   `Measurements <http://docs.openstack.org/admin-guide-cloud/telemetry-measurements.html>`_ .
   You may choose any section *except* OpenStack Compute and then select metric with 'Pollster' Origin.
   For example, let's choose storage.objects.

   Plugin works *correctly* if you see one sample for each resource every polling_interval (1 minute in this example)::

      root@node-2:~# ceilometer sample-list -m storage.objects  -l 10| grep storage.objects
      | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object | 2015-11-05T10:32:27 |
      | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object | 2015-11-05T10:31:29 |

    

   Plugin works *incorrectly* if there are duplications. In this example is seen that every
   ``polling_interval`` there are 3 samples about one resource::

        root@node-2:~# ceilometer sample-list -m storage.objects  -l 20| grep storage.objects
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....|
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....|
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....|
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....|
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....| 
        | 65e486c734394d3ea321ae72639ebe91 | storage.objects | gauge | 0.0    | object ....| 

        .... 2015-11-05T10:27:37 |
        .... 2015-11-05T10:27:26 |
        .... 2015-11-05T10:27:17 |
        .... 2015-11-05T10:26:38 |
        .... 2015-11-05T10:26:26 |
        .... 2015-11-05T10:26:17 |
