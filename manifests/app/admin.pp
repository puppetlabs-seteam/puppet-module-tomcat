class tomcat::app::admin {
  include tomcat::params

  package { $::tomcat::params::admin_package:
    ensure => installed,
    notify => Service['tomcat'],
  }

}
