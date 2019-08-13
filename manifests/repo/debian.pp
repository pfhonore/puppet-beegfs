# Class: beegfs::repo::debian

class beegfs::repo::debian (
  Boolean         $manage_repo    = true,
  Enum['beegfs']  $package_source = $beegfs::package_source,
  Beegfs::Release $release        = $beegfs::release,
) {

  anchor { 'beegfs::apt_repo' : }

  include ::apt

  # If using the old version pattern the release folder is the same as the major
  # version; if using the new pattern we need to replace dots (`.`) with underscore
  # (`_`)
  $_release = if $release =~ /^\d{4}/ {
    $release
  } else {
    $release.regsubst('\.', '_')
  }

  $_os_release = $facts.dig('os', 'release', 'major')

  if $manage_repo {
    case $package_source {
      'beegfs': {
        apt::source { 'beegfs':
          location     => "http://www.beegfs.io/release/beegfs_${_release}",
          repos        => 'non-free',
          architecture => 'amd64',
          release      => "deb${_os_release}",
          key          => {
            'id'     => '055D000F1A9A092763B1F0DD14E8E08064497785',
            'source' => 'http://www.beegfs.com/release/latest-stable/gpg/DEB-GPG-KEY-beegfs',
          },
          include      => {
            'src' => false,
            'deb' => true,
          },
          before       => Anchor['beegfs::apt_repo'],
        }
      }
      default: {
        fail("Unknown package source '${package_source}'")
      }
    }
    Class['apt::update'] -> Package<| tag == 'beegfs' |>
  }
}
