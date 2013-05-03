define tomcat::war(
  $source,
  $ensure  = present,
  $target  = undef,
  $warfile = undef,
  $replace = false,
) {

  # Use the deployment directory + the app name as the default Tomcat target
  $use_target = $target ? {
    undef   => "${tomcat::params::autodeploy_dir}/${name}",
    default => $target,
  }

  # Retrieve (and enforce) the *.war name component of the source
  $use_warfile = $warfile ? {
    undef   => regsubst($source, '.*/([^/]*\.war$)|.*', '\1'),
    default => $warfile,
  }

  if ! $use_warfile { fail("Must specify a warfile (*.war) as source") }

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
        before => Staging::Extract[$use_warfile],
      }

      # Staging::Deploy is a combo declaring Staging::File and Staging::Extract
      staging::deploy { $use_warfile:
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
        subscribe   => Staging::File[$use_warfile],
        before      => [
          Staging::Extract[$use_warfile],
          File[$use_target],
        ],
      }

      # Optionally, always enforce the contents of the warfile. This stanza
      # is dependent on the inner workings of the staging module. The optimal
      # thing to do would be to update staging::file to support replace as a
      # parameter. As it stands it is subject to parse-order problems.
      if $replace {
        File <| title == "${staging::path}/tomcat/${warfile}" |> {
          replace => true,
        }
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
