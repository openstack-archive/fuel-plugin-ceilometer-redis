#
# == Class: redis::main
#
# Installs and configures Redis
#
# === Parameters:
#
# [*primary_controller*]
#   Status of controller node
#   Defaults to false
#
# [*parallel_syncs*]
#   How many slaves we can reconfigure to point to the new slave simultaneously
#   during the failover
#   Defaults to 2
#
# [*quorum*]
#   Tells Sentinel to monitor this master, and to consider it in O_DOWN
#   (Objectively Down) state only if at least <quorum> sentinels agree
#   Defaults to 2
#
# [*down_after_milliseconds*]
#   Number of milliseconds the master (or any attached slave or sentinel) should
#   be unreachable (as in, not acceptable reply to PING, continuously, for the
#   specified period) in order to consider it in S_DOWN state (Subjectively Down)
#   Defaults to 30000
#
# [*failover_timeout*]
#   Specifies the failover timeout in milliseconds
#   Defaults to 60000
#
# [*timeout*]
#   Specifes timeout for ceilometer coordination url
#   Defaults to 10
#
# [*redis_port*]
#   Port for redis-server to listen on
#   Defaults to '6379'
#
# [*redis_sentinel_port*]
#   Port for redis-sentinel to listen on
#   Defaults to '26379'
#

class redis::main (
  $primary_controller      = false,
  $parallel_syncs          = '2',
  $quorum                  = '2',
  $down_after_milliseconds = '30000',
  $failover_timeout        = '60000',
  $timeout                 = '10',
  $primary_redis_node      = '127.0.0.1',
  $redis_hosts             = ['127.0.0.1'],
  $redis_bind_address      = '0.0.0.0',
  $redis_port              = '6379',
  $redis_sentinel_port     = '26379',
) {

  include ceilometer::params
  include redis::params

  case $::osfamily {
    'RedHat': {
      $manage_upstart_scripts = false
    }
    'Debian': {
      $manage_upstart_scripts = true
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}")
    }
  }

  firewall {'121 redis_port':
    port   => $redis_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'122 redis_sentinel_port':
    port   => $redis_sentinel_port,
    proto  => 'tcp',
    action => 'accept',
  }

  if $primary_controller {
    $conf_slaveof = undef
  } else {
    $conf_slaveof = "$primary_redis_node $redis_port"
  }

  # Use custom function to generate sentinel configuration
  $sentinel_confs = sentinel_confs($redis_hosts, $redis_port, $quorum,
                                   $parallel_syncs, $down_after_milliseconds,
                                   $failover_timeout)

  package {'python-redis':
    ensure => 'present',
  } ->

  class { '::redis':
    conf_bind            => $redis_bind_address,
    conf_slave_read_only => 'no',
    service_enable       => false,
    service_ensure       => 'stopped',
    conf_slaveof         => $conf_slaveof,
  } ->

  class { '::redis::sentinel':
    conf_port              => $redis_sentinel_port,
    sentinel_confs         => $sentinel_confs,
    manage_upstart_scripts => $manage_upstart_scripts,
  }

  ceilometer_config {
    'coordination/backend_url'    : value => redis_backend_url($redis_hosts, $redis_sentinel_port, $timeout);
    'coordination/heartbeat'      : value => '1.0';
    'coordination/check_watchers' : value => $timeout;
    'notification/workload_partitioning': value => true
  }

  if $primary_controller {
    exec {'remove_old_resource_central_agent':
      path    => '/usr/sbin:/usr/bin:/sbin:/bin',
      command => 'pcs resource delete p_ceilometer-agent-central --wait=120',
      onlyif  => 'pcs resource show p_ceilometer-agent-central > /dev/null 2>&1',
    }

    exec {'remove_old_resource_alarm_evaluator':
      path => '/usr/sbin:/usr/bin:/sbin:/bin',
      command => 'pcs resource delete p_ceilometer-alarm-evaluator --wait=120',
      onlyif  => 'pcs resource show p_ceilometer-alarm-evaluator > /dev/null 2>&1',
    }

    Exec['remove_old_resource_central_agent'] -> Cluster::Corosync::Cs_service["$::ceilometer::params::agent_central_service_name"]
    Exec['remove_old_resource_alarm_evaluator'] -> Cluster::Corosync::Cs_service["$::ceilometer::params::alarm_evaluator_service_name"]
  }

  file {'redis_ocf_script':
    path   => '/usr/lib/ocf/resource.d/fuel/redis-server',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/redis/ocf/redis-server'
  }

  cluster::corosync::cs_service { "$::ceilometer::params::agent_central_service_name":
    ocf_script          => 'ceilometer-agent-central',
    csr_parameters      => {},
    csr_metadata        => undef,
    csr_complex_type    => 'clone',
    csr_ms_metadata     => { 'interleave' => true },
    csr_mon_intr        => '20',
    csr_mon_timeout     => '10',
    csr_timeout         => '60',
    service_name        => $::ceilometer::params::agent_central_service_name,
    package_name        => $::ceilometer::params::agent_central_package_name,
    service_title       => 'ceilometer-agent-central',
    primary             => $primary_controller,
    hasrestart          => false,
  }

  cluster::corosync::cs_service { "$::ceilometer::params::alarm_evaluator_service_name":
    ocf_script          => 'ceilometer-alarm-evaluator',
    csr_parameters      => {},
    csr_metadata        => undef,
    csr_complex_type    => 'clone',
    csr_ms_metadata     => { 'interleave' => true },
    csr_mon_intr        => '20',
    csr_mon_timeout     => '10',
    csr_timeout         => '60',
    service_name        => $::ceilometer::params::alarm_evaluator_service_name,
    package_name        => $::ceilometer::params::alarm_evaluator_package_name,
    service_title       => 'ceilometer-alarm-evaluator',
    primary             => $primary_controller,
    hasrestart          => false,
  }

  cluster::corosync::cs_service { 'redis':
    ocf_script          => 'redis-server',
    csr_parameters      => {},
    csr_metadata        => undef,
    csr_complex_type    => 'clone',
    csr_ms_metadata     => { 'interleave' => true },
    csr_mon_intr        => '20',
    csr_mon_timeout     => '10',
    csr_timeout         => '60',
    service_name        => $::redis::params::service,
    package_name        => $::redis::params::package,
    service_title       => 'redis',
    primary             => $primary_controller,
    hasrestart          => false,
  }


  File['redis_ocf_script'] ->
  Cluster::Corosync::Cs_service['redis'] ->
  Ceilometer_config <||> ->
  Cluster::Corosync::Cs_service["$::ceilometer::params::agent_central_service_name"] ->
  Cluster::Corosync::Cs_service["$::ceilometer::params::alarm_evaluator_service_name"]

  if !$primary_controller {
    exec {'waiting-for-agent-up-on-primary':
      tries     => 10,
      try_sleep => 30,
      command   => "pcs resource | grep -A 1 p_${::ceilometer::params::agent_central_service_name} | grep Started > /dev/null 2>&1",
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
    }

    exec {'waiting-for-evaluator-up-on-primary':
      tries     => 10,
      try_sleep => 30,
      command   => "pcs resource | grep -A 1 p_${::ceilometer::params::alarm_evaluator_service_name} | grep Started > /dev/null 2>&1",
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
    }

    exec {'waiting-for-redis-up-on-primary':
      tries     => 10,
      try_sleep => 30,
      command   => "pcs resource | grep -A 1 p_${::redis::params::service} | grep Started > /dev/null 2>&1",
      path      => '/usr/sbin:/usr/bin:/sbin:/bin',
    }

    service {"p_${::ceilometer::params::agent_central_service_name}":
      enable     => true,
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }

    service {"p_${::ceilometer::params::alarm_evaluator_service_name}":
      enable     => true,
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }

    service {"p_${::redis::params::service}":
      enable     => true,
      ensure     => 'running',
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }

    Exec['waiting-for-redis-up-on-primary'] ->
    Service["p_${::redis::params::service}"] ->
    Cluster::Corosync::Cs_service['redis'] ->
    Exec['waiting-for-agent-up-on-primary'] ->
    Ceilometer_config <||> ->
    Cluster::Corosync::Cs_service["$::ceilometer::params::agent_central_service_name"] ->
    Exec['waiting-for-evaluator-up-on-primary'] ->
    Cluster::Corosync::Cs_service["$::ceilometer::params::alarm_evaluator_service_name"]
  }

  service { 'ceilometer-agent-central':
    ensure  => 'stopped',
    name    => $::ceilometer::params::agent_central_service_name,
    enable  => false,
  }

  service { 'ceilometer-alarm-evaluator':
    ensure  => 'stopped',
    name    => $::ceilometer::params::alarm_evaluator_service_name,
    enable  => false,
  }

  service { 'ceilometer-agent-notification':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::agent_notification_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
  }

}
