# Class: beegfs::client
#
# This module manages beegfs client
#
class beegfs::client (
  String                $user                     = $beegfs::user,
  String                $group                    = $beegfs::group,
                        $package_ensure           = $beegfs::package_ensure,
                        $kernel_ensure            = present,
  Array[String]         $interfaces               = ['eth0'],
  Stdlib::AbsolutePath  $interfaces_file          = '/etc/beegfs/interfaces.client',
  Beegfs::LogLevel      $log_level                = 3,
  Stdlib::Port          $client_udp               = 8004,
  Stdlib::Port          $helperd_tcp              = 8006,
  Stdlib::Host          $mgmtd_host               = hiera('beegfs::mgmtd_host', $beegfs::mgmtd_host),
  Stdlib::Port          $mgmtd_tcp_port           = 8008,
  Stdlib::Port          $mgmtd_udp_port           = 8008,
  Beegfs::Major_version $major_version            = $beegfs::major_version,
  Array[String]         $kernel_packages          = $beegfs::params::kernel_packages,
  Boolean               $autobuild                = true,
  String                $autobuild_args           = '-j8',
  Boolean               $tune_refresh_on_get_attr = false,
  Boolean               $enable_quota             = $beegfs::enable_quota,
  Boolean               $enable_acl               = $beegfs::enable_acl,
) inherits beegfs {

  require ::beegfs::install

  anchor { 'beegfs::kernel_dev' : }

  ensure_packages($kernel_packages, {
      'ensure' => $kernel_ensure,
      'before' => Anchor['beegfs::kernel_dev']
    }
  )

  file { '/etc/beegfs/beegfs-helperd.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template("beegfs/${major_version}/beegfs-helperd.conf.erb"),
  }

  file { $interfaces_file:
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template('beegfs/interfaces.erb'),
  }

  file { '/etc/beegfs/beegfs-client.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    require =>[
      Package['beegfs-utils'],
      File[$interfaces_file]
    ],
    content => template("beegfs/${major_version}/beegfs-client.conf.erb"),
  }

  file { '/etc/beegfs/beegfs-client-autobuild.conf':
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => template("beegfs/${major_version}/beegfs-client-autobuild.conf.erb"),
  }

  exec { '/etc/init.d/beegfs-client rebuild':
    path        => ['/usr/bin', '/usr/sbin'],
    subscribe   => File['/etc/beegfs/beegfs-client-autobuild.conf'],
    refreshonly => true,
    require     => Package['beegfs-client'],
  }

  package { 'beegfs-helperd':
    ensure => $package_ensure,
  }

  package { 'beegfs-client':
    ensure  => $package_ensure,
    require => Anchor['beegfs::kernel_dev'],
  }

  service { 'beegfs-helperd':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package['beegfs-helperd'],
  }

  concat { '/etc/beegfs/beegfs-mounts.conf':
    owner   => $user,
    group   => $group,
    mode    => '0644',
    require => Package['beegfs-client'],
  }

  service { 'beegfs-client':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => [ Package['beegfs-client'],
      Service['beegfs-helperd'],
      File[$interfaces_file],
    ],
    subscribe  => [
      Concat['/etc/beegfs/beegfs-mounts.conf'],
      File['/etc/beegfs/beegfs-client.conf'],
      File['/etc/beegfs/beegfs-helperd.conf'],
      Exec['/etc/init.d/beegfs-client rebuild'],
      File[$interfaces_file],
    ],
  }
}
