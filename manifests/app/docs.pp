class tomcat::app::docs {
  include tomcat::params

  package { $::tomcat::params::docs_package:
    ensure => installed,
    notify => Service['tomcat'],
  }

}
