define tomcat::war(
  $source,
  $ensure       = present,
  $target       = undef,
  $replace      = false,
) {

  # Use the deployment directory + the app name as the default Tomcat target
  $use_target = $target ? {
    undef   => "${tomcat::params::autodeploy_dir}/${name}",
    default => $target,
  }

  # Retrieve (and enforce) the *.war name component of the source
  $warfile = regsubst($source, '.*/([^/]*\.war$)|.*', '\1')
  if ! $warfile { fail("Must specify a warfile (*.war) as source") }

  case $ensure {
    default: { fail("ensure value must be present or absent; not ${ensure}") }
    'present': {

      # These resource defaults will be passed down through to staging. The
      # important bit is setting the provider to shell.
      Exec {
        path     => $::path,
        provider => shell,
      }

      # For war files the staging module extracts to cwd, so ensure the dir.
      file { $use_target:
        ensure => directory,
        before => Staging::Extract[$warfile],
      }

      # Staging::Deploy is a combo declaring Staging::File and Staging::Extract
      staging::deploy { $warfile:
        source  => $source,
        target  => $use_target,
        unless  => "[ \"`ls -A ${use_target} 2>/dev/null`\" ]",
        notify  => Service['tomcat'],
        require => Package['tomcat'],
      }

      # For upgrades. Clean out the old install before extracting the new one.
      exec { "purge_tomcat_war_${title}":
        command     => shellquote('/bin/rm', '-rf', $use_target),
        refreshonly => true,
        subscribe   => Staging::File[$warfile],
        before      => [
          Staging::Extract[$warfile],
          File[$use_target],
        ],
      }

    }
    'absent': {

      # When ensuring absent, just remove the extracted dir
      file { $use_target:
        ensure  => absent,
        recurse => true,
        purge   => true,
        force   => true,
        backup  => false,
        notify  => Service['tomcat'],
      }

    }
  }

}
