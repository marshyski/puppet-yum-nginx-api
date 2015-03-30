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
class puppet-yum-nginx-api (
  $gunicorn_port = '8888',
  $git_dir       = '/opt/yum-nginx-api',
  $deploy_path   = '/opt/yum-nginx-api/yumapi',
  $log_path      = '/var/log/nginx/yumapi.log',
  $base_dir      = '/opt',
  $repo_dir      = '/opt/repos',
  $upload_dir    = '/opt/repos/pre-release',
  ) {

  # Require NGINX setup before installing yum-nginx-api
  require puppet-yum-nginx-api::nginx

  # Install rpms needed for runtime and build of python packages
  package {
    [
    'supervisor',
    'gcc',
    'createrepo',
    'python-setuptools',
    ]:
      ensure => installed,
  }

  # Install Python pip packages
  package {
    [
    'Flask',
    'Werkzeug',
    'gunicorn',
    'python-magic',
    'SQLAlchemy',
    ]:
      ensure   => installed,
      provider => pip,
  }

  file { $repo_dir:
    ensure => directory,
    mode   => '0755',
  }

  file { $upload_dir:
    ensure  => directory,
    mode    => '0755',
    require => File[$repo_dir],
  }

  file { '/etc/nginx/mime.types':
    ensure  => present,
    content => template('puppet-yum-nginx-api/mime.erb'),
  }

  file { '/etc/supervisord.conf':
    ensure  => present,
    content => template('puppet-yum-nginx-api/supervisor.erb'),
    require => Package['supervisor'],
  }

  # Install git repo into git directory
  vcsrepo { $git_dir:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/FINRAOS/yum-nginx-api.git',
    revision => 'master',
    require  => Package['supervisor'],
  }

  # Manage Python supervisor daemon
  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['/etc/supervisord.conf'],
    require    => File['/etc/supervisord.conf'],
  }
}
