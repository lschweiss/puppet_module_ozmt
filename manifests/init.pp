# Class: ozmt
# ===========================
#
# This module deploys OZMT management scripts and related configuration.
#
# @param [String] ozmt_repo_source The URL for the OZMT repo, default https://bitbucket.org/ozmt/ozmt
# @param [Variant] ozmt_repo_revision Optional, the revision to specify for *ozmt_repo_source*.  Defaults
#   to latest.
# @param [String] ozmt_install_dir Where to put OZMT repo contents, default /opt/ozmt.
# @param [String] email_to Recipient email address for reporting, goes in config.common.
# @param [String] email_from Optional, sender email address for reporting, goes in reporting.muttrc.
#   Note this param is mutually exclusive from *email_from_suffix* below.
# @param [String] email_from_suffix Optional, the suffix to append to the sender email address saved
#   in reporting.muttrc.  If this param is used, ozmt module will append the machine's hostname in all
#   caps, to create the full sender address.  E.g. for suffix "-no-reply@domain.com" this module would
#   use the sender address "HOSTNAME-no-reply@domain.com" .  Note this param is mutually exclusive from
#   *email_from* above.
# @param [String] user OZMT user, default ozmt.
# @param [Integer] uid Optional OZMT user UID, defaults to whatever OS selects.
# @param [Variant] group OZMT user group or GID, default ozmt.
# @param [Integer] gid Optional OZMT group GID, defaults to whatever OS selects.  This parameter can't
#   be specified if a number is specified for *group* above.
# @param [String] ozmt_private_ssh_key Optional, content of /var/ozmt/private_ssh_key.
# @param [String] config_hostname Optional, content of /etc/ozmt/config.${hostname}.
# @param [Array] group_members NOT YET IMPLEMENTED Optional, array additional usernames to add to group
#   *group*.  These usernames must exist at the time of catalog compilation.  Also, this array shouldn't
#   include the ozmt username specified in *user* above.
#
# @example Declaring the class
#    class { 'ozmt':
#      ozmt_repo_source => 'https://bitbucket.org/myuser/custom-ozmt',
#      ozmt_repo_revision => 'unstable',
#      email_from_suffix => '-no-reply@domain.com',
#    }
#
# @author NRG nrg-admin@nrg.wustl.edu Copyright 2018
#
class ozmt (
  String $ozmt_repo_source = 'https://bitbucket.org/ozmt/ozmt',
  Optional[Variant] $ozmt_repo_revision = undef,
  Boolean $bleeding_edge = true,
  String $ozmt_install_dir = '/opt/ozmt',
  String $email_to,
  Optional[String] $email_from = undef,
  Optional[String] $email_from_suffix = undef,
  String $user = 'ozmt',
  String $group = 'ozmt',
  Optional[Integer] $uid = undef,
  Optional[Integer] $gid = undef,
  Optional[String] $ozmt_private_ssh_key = undef,
  Optional[String] $config_hostname = undef,
  ){

  # Check on package prerequisites
  case $::osfamily {
    'Solaris' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['CSWmercurial']) .
      # TODO: Verify column is installed, e.g. if defined(Package['CSWcolumn']) .
      cron {
        'clean-dead-disk-links':
          command => "/usr/sbin/devfsadm -C -v",
          user => 'root',
          minute => 35,

      }
      $user_shell = '/usr/gnu/bin/false'
    }
    'RedHat' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
      # TODO: Verify util-linux is installed, e.g. if defined(Package['util-linux']) .
      $user_shell = '/bin/false'
    }
    'Debian' : {
      # TODO: Verify mercurial is installed, e.g. if defined(Package['hg']) .
      # TODO: Verify util-linux is installed, e.g. if defined(Package['util-linux']) .
      $user_shell = '/bin/false'
    }
    default : {
      fail("Unsupported os: ${::osfamily}")
    }
  }

  # Create puppet user and group
  user { $user:
    home => $ozmt_install_dir,
    uid => $uid,
    gid => $group,
    shell => "$user_shell",
    require => [ Group["${group}"], File[$ozmt_install_dir] ];
  }
  group { $group:
    ensure => present,
    gid => $gid,
  }

  # Check out OZMT repo
  file { $ozmt_install_dir:
    ensure => directory;
  }
  ->
  vcsrepo { $ozmt_install_dir:
    ensure   => $bleeding_edge ? {
                  true    => latest,
                  default => present, 
                },
    provider => git,
    revision => $ozmt_repo_revision,
    source   => $ozmt_repo_source,
    notify   => Exec['setup-ozmt-links'];
  }

  $realname = upcase($::hostname)
  if $email_from {
    $email_from_real = $email_from 
  }
  elsif $email_from_suffix {
    $email_from_real = "${realname}${email_from_suffix}" 
  }
  else {
    $email_from_real = 'root@localhost'
  }

  if $ozmt_private_ssh_key {
    file {
      '/var/ozmt':
        owner  => "$user",
        mode   => '0700',
        ensure => directory;
      '/var/ozmt/private_ssh_key':
        owner   => "$user",
        mode    => '0600',
        content => "$ozmt_private_ssh_key",
        require => File['/var/ozmt'];
      '/root/.ssh/config':
        owner  => 'root',
        mode   => '600',
        source => 'puppet:///modules/ozmt/root_ssh_config';
    }
  }
  
  # File resources
  file { 
    '/etc/ozmt':
      ensure => directory;
  }
  ->
  file {
    '/etc/ozmt/config':
      ensure => present,
      replace => false,
      source => 'puppet:///modules/ozmt/config';
    '/etc/ozmt/config.network':
      ensure => present,
      replace => true,
      source => 'puppet:///modules/ozmt/config.network';
    '/etc/ozmt/config.common':
      ensure => present,
      replace => true,
      content => template('ozmt/config.common.erb');
    '/etc/ozmt/jbod-map':
      ensure  => present,
      replace => true,
      source  =>  'puppet:///modules/ozmt/jbod-map';
    '/etc/ozmt/replication':
      ensure  => present,
      replace => true,
      recurse => true,
      source  => 'puppet:///modules/ozmt/replication';
    '/etc/ozmt/network':
      ensure  => present,
      replace => true,
      recurse => true,
      source  =>  'puppet:///modules/ozmt/network';
    '/etc/ozmt/samba':
      ensure => present,
      replace => false,
      recurse => true,
      source => 'puppet:///modules/ozmt/samba';
    '/etc/ozmt/reporting.muttrc':
      ensure => present,
      content => template('ozmt/reporting.muttrc.erb');
  }

  if $config_hostname {
    file {
      "/etc/ozmt/config.${hostname}":
        ensure  => present,
        replace => true,
        content => "$config_hostname",
        require =>  File['/etc/ozmt'];
    }
  }

  # Set up links
  exec { 'setup-ozmt-links':
    command     => "${ozmt_install_dir}/setup-ozmt-links.sh",
    refreshonly => true,
    subscribe   => Vcsrepo[$ozmt_install_dir],
    require     => [ Vcsrepo[$ozmt_install_dir],
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

    'ozmt-check-zpool-status':
      command => "${ozmt_install_dir}/reporting/zpool-status-report.sh 1>/dev/null",
      user    => 'root',
      hour    => [ 0, 6, 12, 18 ],
      minute  => 0,
      require => Vcsrepo[$ozmt_install_dir];


    'ozmt-process-crons-hourly':
      command => "${ozmt_install_dir}/utils/ozmt-cron.sh hourly 1>/dev/null",
      user    => 'root',
      minute  => 0,
      require =>  Vcsrepo[$ozmt_install_dir];
    'ozmt-process-crons-daily':
      command => "${ozmt_install_dir}/utils/ozmt-cron.sh daily 1>/dev/null",
      user    => 'root',
      hour    => 0,
      minute  => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-crons-weekly':
      command => "${ozmt_install_dir}/utils/ozmt-cron.sh weekly 1>/dev/null",
      user    => 'root',
      hour    => 0,
      minute  => 0,
      weekday => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-process-crons-monthly':
      command  => "${ozmt_install_dir}/utils/ozmt-cron.sh monthly 1>/dev/null",
      user     => 'root',
      hour     => 0,
      minute   => 0,
      monthday => 1,
      require  => Vcsrepo[$ozmt_install_dir];

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
      minute => [5, 35];
    'ozmt-send-report':
      command => "${ozmt_install_dir}/reporting/send_report.sh 1>/dev/null",
      user => 'root',
      minute => 0,
      hour => 0,
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-quota-reports':
      command => "${ozmt_install_dir}/reporting/quota-reports.sh 1>/dev/null",
      user => 'root',
      minute => [0, 15, 30, 45],
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-cache-refresh':
      command => "${ozmt_install_dir}/utils/zfs-cache-refresh.sh 1>/dev/null",
      user    => 'root',
      hour    =>  [11, 23],
      minute  =>  fqdn_rand(60),
      require => Vcsrepo[$ozmt_install_dir];
    'ozmt-usage-report-monthly':
      command  => "${ozmt_install_dir}/reporting/usage-reports.sh 1>/dev/null",
      user     => 'root',
      minute   => 0,
      hour     => 0,
      monthday => 1,
      require  =>  Vcsrepo[$ozmt_install_dir];
  }
  
  
}
