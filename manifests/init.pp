class puppet-yum-nginx-api (
  $gunicorn_port = '8888',
  $deploy_path   = '/opt/yum-nginx-api/yumapi',
  $log_path      = '/var/log/nginx/yumapi.log',
  $base_dir      = '/opt',
  $repo_dir      = '/opt/repos',
  $upload_dir    = '/opt/repos/pre-release',
  ) {

  require puppet-yum-nginx-api::nginx

  package {
    [
    'python-pip',
    'supervisor',
    'gcc',
    'createrepo',
    'python-setuptools',
    ]:
      ensure => installed,
  }

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
      require  => Package['python-pip'],
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

  file { '/etc/supervisord.d/yumapi.conf':
    ensure  => present,
    content => template('puppet-yum-nginx-api/yumapi.erb'),
    require => Package['supervisor'],
  }

  file { '/etc/supervisord.conf':
    ensure  => present,
    content => template('puppet-yum-nginx-api/supervisord.erb'),
    require => Package['supervisor'],
  }

  vcsrepo { $base_dir:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/FINRAOS/yum-nginx-api.git',
    revision => 'master',
    require  => Package['supervisor'],
  }

  service { 'supervisor':
    ensure     => started,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [File['/etc/supervisord.conf'],File['/etc/supervisord.d/yumapi.conf']],
  }
}
