class tomcat (
  $version = 'present',
  $package = $tomcat::params::tomcat_package,
) inherits tomcat::params {
  include java

  package { 'tomcat':
    ensure => $version,
    name   => $package,
    before => Service['tomcat'],
  }

  service { 'tomcat':
    ensure => running,
    enable => true,
    name   => $tomcat::params::service,
  }

  file { $tomcat::params::autodeploy_dir:
    ensure  => directory,
  }
  file { $tomcat::params::staging_dir:
    ensure  => directory,
  }

}
