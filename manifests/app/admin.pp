class tomcat::app::admin {
  include tomcat::params

  package { $::tomcat::params::admin_package:
    ensure => installed,
    notify => Service['tomcat'],
  }
  package { $::tomcat::params::extra_packages:
    ensure  => installed,
    notify  => Service['tomcat'],
    require => Package[$::tomcat::params::admin_package],
  }

}
