class puppet-yum-nginx-api (
  $gunicorn_port = '8888',
  $git_dir       = '/opt/yum-nginx-api',
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

  file { '/etc/supervisord.conf':
    ensure  => present,
    content => template('puppet-yum-nginx-api/supervisor.erb'),
    require => Package['supervisor'],
  }

  vcsrepo { $git_dir:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/FINRAOS/yum-nginx-api.git',
    revision => 'master',
    require  => Package['supervisor'],
  }

  service { 'supervisord':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => File['/etc/supervisord.conf'],
  }
}
