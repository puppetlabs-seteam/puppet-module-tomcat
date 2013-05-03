class tomcat::params {

  case $::osfamily {
    default: { fail("unsupported OS: ${::osfamily}") }
    'RedHat': {
      $tomcat_package  = 'tomcat6'
      $admin_package   = 'tomcat6-admin-webapps'
      $docs_package    = 'tomcat6-docs-webapp'
      $service         = 'tomcat6'
      $autodeploy_dir  = '/var/lib/tomcat6/webapps'
      $staging_dir     = '/var/lib/tomcat6/staging'
    }
    'Debian': {
      $tomcat_package = 'tomcat6'
      $admin_package  = 'tomcat6-admin'
      $docs_package   = 'tomcat6-docs'
      $service        = 'tomcat6'
      #$autodeploy_dir  = '/var/lib/tomcat6/webapps'
      #$staging_dir     = '/var/lib/tomcat6/staging'
    }
  }

}
