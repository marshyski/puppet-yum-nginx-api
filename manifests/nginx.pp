# == Class: puppet-yum-nginx-api
#
# This module gets you setup with yum-nginx-api, and is completely extensible if want to manage yum repos with NGINX web server.
#
# === Authors
#
# Tim Ski <marshyski@gmail.com>
#
# === Copyright
#
# Copyright 2014 Tim Ski
#
class puppet-yum-nginx-api::nginx (
  $nginx_ver    = 'latest',
  $nginx_port   = '80',
  $nginx_user   = 'nginx',
  $nginx_group  = 'nginx',){

# Install NGINX from EPEL
  package { 'nginx':
    ensure  => $nginx_ver,
  }

# Manage the security limits
  file { '/etc/security/limits.d/nginx.conf':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('puppet-yum-nginx-api/security_limits.conf'),
    require => Package['nginx'],
  }

# Set sysctl values for NGINX
  augeas {'sysctl_for_nginx':
    context => '/files/etc/sysctl.conf',
    lens    => 'sysctl.lns',
    incl    => '/etc/sysctl.conf',
    changes => [
                'set vm.swappiness 0',
                'set fs.file-max 70000',
                "set net.ipv4.ip_local_port_range '2000 65000'",
                'set net.ipv4.tcp_window_scaling 1',
                'set net.ipv4.tcp_max_syn_backlog 250000',
                'set net.core.netdev_max_backlog 4000',
                'set net.core.somaxconn 4000',
                'set net.ipv4.tcp_max_tw_buckets 1440000',
                'set net.core.rmem_default 8388608',
                'set net.core.rmem_max 16777216',
                'set net.core.wmem_max 16777216',
                "set net.ipv4.tcp_rmem '4096 87380 16777216'",
                "set net.ipv4.tcp_wmem '4096 65536 16777216'",
                'set net.ipv4.tcp_congestion_control cubic',
                'set net.ipv4.tcp_fin_timeout 30',
                'set net.ipv4.tcp_keepalive_time 600',
                'set net.ipv4.tcp_keepalive_probes 5',
                'set net.ipv4.tcp_keepalive_intvl 15',
                'set net.ipv4.tcp_tw_recycle 1',
                'set net.ipv4.tcp_timestamps 1',
                'set net.ipv4.tcp_tw_reuse 1',
                'set net.ipv4.tcp_sack 0',
                'set net.ipv4.tcp_dsack 0',
                'set net.ipv4.tcp_synack_retries 3',
                ],
    notify  => Exec['sysctl_restart'],
    require => File['/etc/security/limits.d/nginx.conf'],
  }

  exec { 'sysctl_restart':
    command     => '/sbin/sysctl -e -p',
    refreshonly => true,
  }

# Manage NGINX service
  service { 'nginx':
    ensure    => running,
    enable    => true,
    hasstatus => true,
    require   => File['/etc/security/limits.d/nginx.conf'],
  }

# Set NGINX service configuration
  file { '/etc/nginx/nginx.conf':
    ensure  => present,
    owner   => nginx,
    group   => nginx,
    mode    => '0644',
    content => template('puppet-yum-nginx-api/nginx.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

# Reconfigure log rotation for access/error logs
  file { '/etc/logrotate.d/nginx':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('puppet-yum-nginx-api/nginx'),
    require => Package['nginx'],
  }

# Set logging directory
  file { '/var/log/nginx':
    ensure  => directory,
    owner   => nginx,
    group   => nginx,
    mode    => '0700',
    require => Package['nginx'],
  }

# Remove default installed files from NGINX package
  file {
        [
          '/usr/share/nginx/html/index.html',
          '/usr/share/nginx/html/404.html',
          '/usr/share/nginx/html/50x.html',
          '/usr/share/nginx/html/nginx-logo.png',
          '/usr/share/nginx/html/poweredby.png',
        ]:
          ensure  => absent,
          require => Package['nginx'],
  }

  file { '/etc/nginx/conf.d/default.conf':
    ensure  => absent,
    force   => true,
    require => Package['nginx'],
  }
}
