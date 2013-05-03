define tomcat::war(
  $source,
  $ensure  = present,
  $staging = undef,
  $warfile = undef,
  $replace = false,
) {
  $deploy_symlink = "${tomcat::params::autodeploy_dir}/${name}"

  # Retrieve (and enforce) the *.war name component of the source
  $use_warfile = $warfile ? {
    undef   => regsubst($source, '.*/([^/]*\.war$)|.*', '\1'),
    default => $warfile,
  }
  if ! $use_warfile { fail("Must specify a warfile (*.war) as source") }

  # Use the staging directory + the warfile name as the default staging
  # location
  $use_staging = $staging ? {
    undef   => "${tomcat::params::staging_dir}/${use_warfile}.d",
    default => $staging,
  }

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
      file { $use_staging:
        ensure => directory,
        before => Staging::Extract[$use_warfile],
      }

      # Staging::Deploy is a combo declaring Staging::File and Staging::Extract
      staging::deploy { $use_warfile:
        source  => $source,
        target  => $use_staging,
        unless  => "[ \"`ls -A ${use_staging} 2>/dev/null`\" ]",
        notify  => Service['tomcat'],
        require => Package['tomcat'],
      }

      # For in-place upgrades. Clean out any old install before extracting the
      # new one.
      exec { "purge_tomcat_war_${title}":
        command     => shellquote('/bin/rm', '-rf', $use_staging),
        refreshonly => true,
        subscribe   => Staging::File[$use_warfile],
        before      => [
          Staging::Extract[$use_warfile],
          File[$use_staging],
          File["${tomcat::params::autodeploy_dir}/${name}"],
        ],
      }

      # To make the thing live, use a symlink in the autodeploy directory
      file { $deploy_symlink:
        ensure  => symlink,
        target  => $use_staging,
        require => Staging::Extract[$use_warfile],
        notify  => Service['tomcat'],
      }

      # Optionally, always enforce the contents of the warfile. This stanza
      # is dependent on the inner workings of the staging module. The better
      # thing to do would be to update staging::file to support replace as a
      # parameter. As it stands this is subject to parse-order problems.
      if $replace {
        File <| title == "${staging::path}/tomcat/${warfile}" |> {
          replace => true,
        }
      }

    }
    'absent': {

      file { $deploy_symlink:
        ensure => absent,
        notify => Service['tomcat'],
      }
      file { $use_staging:
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
