class tomcat::params {

  case $::osfamily {
    'RedHat': {
      $tomcat_package = 'tomcat6'
      $admin_package  = 'tomcat6-admin-webapps'
      $docs_package   = 'tomcat6-docs-webapp'
      $service        = 'tomcat6'
    }
    'Debian': {
      $tomcat_package = 'tomcat6'
      $admin_package  = 'tomcat6-admin'
      $docs_package   = 'tomcat6-docs'
      $service        = 'tomcat6'
    }
  }

}
