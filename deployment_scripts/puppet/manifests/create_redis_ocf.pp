include redis::params

$ensure             = 'present'
$service_name       = $redis::params::service
$ocf_root_path      = '/usr/lib/ocf'
$handler_root_path  = '/usr/local/bin'
$primitive_provider = 'fuel'
$primitive_type     = $redis::params::service
$ocf_script_name    = "${service_name}-ocf-file"
$ocf_script_file    = 'redis/ocf/redis-server'
$ocf_handler_name   = "ocf_handler_${service_name}"
$ocf_dir_path       = "${ocf_root_path}/resource.d"
$ocf_script_path    = "${ocf_dir_path}/${primitive_provider}/${$primitive_type}"
$ocf_handler_path   = "${handler_root_path}/${ocf_handler_name}"


file { $ocf_script_name :
      ensure  => $ensure,
      path    => $ocf_script_path,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///modules/${ocf_script_file}",
}
