class tomcat (
  $version = 'present',
  $package = $tomcat::params::package,
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

}
