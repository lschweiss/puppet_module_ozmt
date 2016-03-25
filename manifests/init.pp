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
# * `email_to`
#  Recipient email address for reporting, goes in config.common
#
# * `email_from`
#  Sender email address for reporting, goes in reporting.muttrc
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
  String $email_to,
  String $email_from,
  Optional[Variant] $ozmt_repo_revision = undef,
  ){

  # Check on package prerequisites
  case $::osfamily {
    'Solaris' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['CSWmercurial']) .
      # TODO: Verify column is installed, e.g. if defined(Package['CSWcolumn']) .
    }
    'RedHat' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
      # TODO: Verify util-linux is installed, e.g. if defined(Package['util-linux']) .
    }
    'Debian' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
      # TODO: Verify util-linux is installed, e.g. if defined(Package['util-linux']) .
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

  $realname = upcase($::hostname)
  
  # File resources
  file {
    '/etc/ozmt/config':
      source => 'puppet:///modules/ozmt/config';
    '/etc/ozmt/config.network':
      source => 'puppet:///modules/ozmt/config.network';
    '/etc/ozmt/config.common':
      content => template('ozmt/config.common.erb');
    '/etc/ozmt/NIL.conf.template':
      source => 'puppet:///modules/ozmt/NIL.conf.template';
    '/etc/ozmt/NIL-share.conf.template':
      source => 'puppet:///modules/ozmt/NIL-share.conf.template';
    '/etc/ozmt/NRG.conf.template':
      source => 'puppet:///modules/ozmt/NRG.conf.template';
    '/etc/ozmt/NRG-share.conf.template':
      source => 'puppet:///modules/ozmt/NRG-share.conf.template';
    '/etc/ozmt/reporting.muttrc':
      content => template('ozmt/reporting.muttrc.erb');
  }

  # Set up links
  exec { 'setup-ozmt-links':
    command => "${ozmt_install_dir}/setup-ozmt-links.sh",
    creates => '/usr/sbin/ozmt-snapjobs-mod.sh',
    require => [ Vcsrepo[$ozmt_install_dir],
                File['/etc/ozmt/config'],
                File['/etc/ozmt/config.common'],
                File['/etc/ozmt/config.network'] ];
  }

  # Cronjobs
  cron {
    'ozmt-process-snaps-15min':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh 15min 1>/dev/null",
      user => 'root',
      minute => [0, 15, 30, 45],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-hourly':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh hourly 1>/dev/null",
      user => 'root',
      minute => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-mid-day':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh mid-day 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 12,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-daily':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh daily 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-daily-delayed':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh daily-delayed 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 1,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-daily-weekday':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh weekday 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      weekday => [1, 2, 3, 4, 5],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-daily-weekday-evening':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh weekday-evening 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 18,
      weekday => [1, 2, 3, 4, 5],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-weekly':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh weekly 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      weekday => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-monthly':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh monthly 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      monthday => 1,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-bi-annual-1':
      command => "${ozmt_install_dir}/process-snaps.sh bi-annual 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      monthday => 1,
      month => 1,
      require => Vcsrepo[$ozmt_install_dir];    
    'ozmt-process-snaps-bi-annual-7':
      command => "${ozmt_install_dir}/process-snaps.sh bi-annual 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      monthday => 1,
      month => 7,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-snaps-annual':
      command => "${ozmt_install_dir}/snapshots/process-snaps.sh annual 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      monthday => 1,
      month => 1,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-clean-snaps':
      command => "${ozmt_install_dir}/snapshots/clean-snaps.sh 1>/dev/null",
      user => 'root',
      minute => [2, 17, 32, 47],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-schedule-replication':
      command => "${ozmt_install_dir}/replication/schedule-replication.sh 1>/dev/null",
      user => 'root',
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-replication-job-runner':
      command => "${ozmt_install_dir}/replication/replication-job-runner.sh 1>/dev/null",
      user => 'root',
      minute => [1, 11, 21, 31, 41, 51],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-replication-job-cleaner':
      command => "${ozmt_install_dir}/replication/replication-job-cleaner.sh 1>/dev/null",
      user => 'root',
      minute => [5, 15, 25, 34, 45, 55],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-send-report':
      command => "${ozmt_install_dir}/reporting/send-report.sh 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-quota-reports':
      command => "${ozmt_install_dir}/quota-reports.sh 1>/dev/null",
      user => 'root',
      minute => [0, 15, 30, 45],
      require => Vcsrepo[$ozmt_install_dir];    
  }
  
  
}
