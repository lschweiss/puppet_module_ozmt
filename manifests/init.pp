# Class: ozmt
# ===========================
#
# Full description of class ozmt here.
#
# Parameters
# ----------
#
# Document parameters here.
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
# Variables
# ----------
#
# Here you should define a list of variables that this module would require.
#
# * `sample variable`
#  Explanation of how this variable affects the function of this class and if
#  it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#  External Node Classifier as a comma separated list of hostnames." (Note,
#  global variables should be avoided in favor of class parameters as
#  of Puppet 2.6.)
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
  $ozmt_repo_source = 'https://bitbucket.org/nrg/xnat_builder_1_6dev',
  $ozmt_repo_revision = undef,
  $ozmt_install_dir = '/opt/ozmt',
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
