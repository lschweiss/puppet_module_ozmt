# Class: ozmt
# ===========================
#
# Full description of class ozmt here.
#
# Parameters
# ----------
#
# Parameters used by this module.
#
# * `ozmt_repo_source`
#  The URL for the OZMT repo, default https://bitbucket.org/ozmt/ozmt
#
# * `ozmt_repo_revision`
#  The revision to specify for *ozmt_repo_source*.  Will use latest
#   revision when undef.
#
# * `ozmt_install_dir`
#  Where to put OZMT repo contents, default /opt/ozmt .
#
# * `user`
#  OZMT user, default ozmt
#
# * `group`
#  OZMT user group, default ozmt
#
# * `group_members`
#  Optional, array additional usernames to add to group `group`.  Note these usernames must
#  exist at the time of catalog compilation.  Also, this array shouldn't include the ozmt
#  username specified in `user` above.
#
# Variables
# ----------
#
# Variables used by this module.
#
# NONE
#
# Examples
# --------
#
# @example
#    class { 'ozmt':
#      ozmt_repo_source => 'https://bitbucket.org/myuser/custom-ozmt',
#      ozmt_repo_revision => 'unstable',
#    }
#
# Authors
# -------
#
# Author Name <author@domain.com>
#
# Copyright
# ---------
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class ozmt (
  String $ozmt_repo_source = 'https://bitbucket.org/ozmt/ozmt',
  String $ozmt_install_dir = '/opt/ozmt',
  String $user = 'ozmt',
  String $group = 'ozmt',
  Optional[Variant] $ozmt_repo_revision = undef,
  ){

  # Check on package prerequisites
  case $::osfamily {
    'Solaris' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['mercurial']) .
    }
    'RedHat' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
    }
    'Debian' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
    }
    default : {
      fail("Unsupported os: ${::osfamily}")
    }
  }

  # Create puppet user and group
  user { $user:
    home => $ozmt_install_dir,
    gid => $group,
    shell => '/usr/gnu/bin/false',
    require => [ Group["${group}"], File[$ozmt_install_dir] ];
  }
  group { $group:
    ensure => present,
  }

  # Check out OZMT repo
  file { $ozmt_install_dir:
    ensure => directory;
  }
  ->
  vcsrepo { $ozmt_install_dir:
    ensure => present,
    provider => hg,
    revision => $ozmt_repo_revision,
    source => $ozmt_repo_source;
  }

}
