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
  $master_name             = 'mymaster',
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

  $metadata = {
    'resource-stickiness' => '1',
  }

  $operations = {
    'monitor'  => {
      'interval' => '20',
      'timeout'  => '10',
    },
    'start'    => {
      'timeout'  => '360',
    },
    'stop'     => {
      'timeout'  => '360',
    },
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
  $masters_to_monitor = [
    { name => $master_name,
      addr => $primary_redis_node
    },
  ]
  $sentinel_confs = sentinel_confs($masters_to_monitor, $redis_port, $quorum,
                                   $parallel_syncs, $down_after_milliseconds,
                                   $failover_timeout)

  package {'python-redis':
    ensure => 'present',
  } ->

  class { '::redis':
    conf_bind            => $redis_bind_address,
    conf_slave_read_only => 'no',
    service_enable       => true,
    service_ensure       => 'running',
    conf_slaveof         => $conf_slaveof,
  } ->

  class { '::redis::sentinel':
    conf_port              => $redis_sentinel_port,
    sentinel_confs         => $sentinel_confs,
    manage_upstart_scripts => $manage_upstart_scripts,
    master_name            => $master_name
  }

  ceilometer_config {
    'coordination/backend_url'    : value => redis_backend_url($redis_hosts, $redis_sentinel_port, $timeout, $master_name);
    'coordination/heartbeat'      : value => '1.0';
    'coordination/check_watchers' : value => $timeout;
  }

  service { 'ceilometer-agent-central':
    ensure  => 'running',
    name    => $::ceilometer::params::agent_central_service_name,
    enable  => true,
  }

  pacemaker_wrappers::service { $::ceilometer::params::agent_central_service_name :
    complex_type    => 'clone',
    ms_metadata     => { 'interleave' => true },
    primitive_type  => 'ceilometer-agent-central',
    metadata        => $metadata,
    parameters      => { 'user' => 'ceilometer' },
    operations      => $operations,
  }

  pacemaker_wrappers::service { 'redis-server' :
    ocf_script_file => 'redis/ocf/redis-server',
    complex_type    => 'clone',
    ms_metadata     => { 'interleave' => true },
    primitive_type  => 'redis-server',
    operations      => $operations,
  }

  Pacemaker_wrappers::Service['redis-server'] ->
  Pacemaker_wrappers::Service["$::ceilometer::params::agent_central_service_name"]

  Ceilometer_config <||> ~> Service["$::ceilometer::params::agent_central_service_name"]

}
