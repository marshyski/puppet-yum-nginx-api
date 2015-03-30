# puppet-yum-nginx-api

Puppet Module for yum-nginx-api https://github.com/FINRAOS/yum-nginx-api

----------

**Overview:**

This module gets you setup with *yum-nginx-api*, and is completely extensible if want to manage yum repos with NGINX web server.

----------

**Dependencies:**

    puppet module install puppetlabs-vcsrepo
    puppet module install stankevich-python
    puppet module install stahnma-epel

----------

**Variables:**

*init.pp:*

      $gunicorn_port = '8888',
      $git_dir       = '/opt/yum-nginx-api',
      $deploy_path   = '/opt/yum-nginx-api/yumapi',
      $log_path      = '/var/log/nginx/yumapi.log',
      $base_dir      = '/opt',
      $repo_dir      = '/opt/repos',
      $upload_dir    = '/opt/repos/pre-release',

*nginx.pp:*

      $nginx_ver    = 'latest',
      $nginx_port   = '80',
      $nginx_user   = 'nginx',
      $nginx_group  = 'nginx',

----------

**Tested Againsted:**

 - CentOS/RHEL 6.x
