# == Class: puppet_yum_nginx_api
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
class puppet_yum_nginx_api (
  $gunicorn_port = '8888',
  $git_dir       = '/opt/yum-nginx-api',
  $deploy_path   = '/opt/yum-nginx-api/yumapi',
  $log_path      = '/var/log/nginx/yumapi.log',
  $base_dir      = '/opt',
  $repo_dir      = '/opt/repos',
  $upload_dir    = '/opt/repos/pre-release',
  ) {

  # Require NGINX and git setup before installing yum-nginx-api
  require puppet_yum_nginx_api::nginx
  require git

  # Install rpms needed for runtime and build of python packages
  package {
    [
    'supervisor',
    'gcc',
    'createrepo',
    'python-setuptools',
    'python-pip',
    ]:
      ensure => installed,
  }

  # Install Python pip packages
  exec {'pip install':
    command => '/usr/bin/pip install Flask Werkzeug gunicorn python-magic SQLAlchemy',
    unless  => '/usr/bin/pip freeze | grep -i flask',
    require => Package['python-pip'],
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
    content => template('puppet_yum_nginx_api/mime.erb'),
  }

  file { '/etc/supervisord.conf':
    ensure  => present,
    content => template('puppet_yum_nginx_api/supervisor.erb'),
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

  # Manage gunicorn bash script
  file { '/opt/yum-nginx-api/yumapi/yumapi.sh':
    ensure  => present,
    content => template('puppet_yum_nginx_api/yumapish.erb'),
    require => Vcsrepo["$git_dir"],
  }

  # Manage Python supervisor daemon
  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => File['/etc/supervisord.conf'],
    require    => [File['/etc/supervisord.conf'], Exec['pip install']],
  }
}
