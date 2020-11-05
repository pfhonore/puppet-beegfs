# Manages APT repositories for Debian distros

class beegfs::repo::debian (
  Boolean         $manage_repo    = true,
  Enum['beegfs']  $package_source = $beegfs::package_source,
  Beegfs::Release $release        = $beegfs::release,
) {

  anchor { 'beegfs::apt_repo' : }

  include apt

  # If using the old version pattern the release folder is the same as the major
  # version; if using the new pattern we need to replace dots (`.`) with underscore
  # (`_`)
  $_release = if $release =~ /^\d{4}/ {
    $release
  } else {
    $release.regsubst('\.', '.')
  }

  case $release {
    '2015.03','6': {
      # 'deb8', 'deb9', etc.
      $major = $facts.dig('os', 'release', 'major')
      $_os_release = "deb${major}"
    }
    # '7' onwards uses traditional Debian codename
    default: {
      case $facts.dig('os', 'name') {
        # https://askubuntu.com/questions/445487/what-debian-version-are-the-different-ubuntu-versions-based-on
        'Ubuntu': {
          case $facts.dig('os', 'release', 'full') {
            '14.04','14.10','15.04','15.10':{
              $_os_release = 'deb8'
            }
            '16.04','16.10','17.04','17.10':{
              $_os_release = 'stretch'
            }
            default: {
              $_os_release = 'stretch'
            }
          }
        }
        default: {
          case $facts.dig('os', 'distro', 'codename') {
            'buster':{
              $_os_release = 'stretch'
            }
            default: {
              $_os_release = $facts.dig('os', 'distro', 'codename')
            }
          }
        }
      }
    }
  }

  if $manage_repo {
    case $package_source {
      'beegfs': {
        apt::source { 'beegfs':
          location     => "http://www.beegfs.io/release/beegfs_${_release}",
          repos        => 'non-free',
          architecture => 'amd64',
          release      => $_os_release,
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
