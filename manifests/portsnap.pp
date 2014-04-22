class freebsd::portsnap {
  $_portsdir = $freebsd::_portsdir
  $_portsnap_conf = $portsnap_conf ? { '' => '/etc/portsnap.conf', default => $portsnap_conf }
  $_portsnapdir = $portsnapdir ? { '' => '/var/db/portsnap', default => $portsnapdir }
  $_portsnap_bin = $portsnap_bin ? { '' => '/usr/sbin/portsnap', default => $portsnap_bin }
  $_portsnap_flags = $portsnap_flags ? { '' => "-d \"$_portsnapdir\" -f \"$_portsnap_conf\" -p \"$_portsdir\"", default => $_portsnap_flags }

  $__portsnap = "$_portsnap_bin $_portsnap_flags"

  file {
    "$_portsnapdir":
    path => "$_portsnapdir",
    ensure => directory,
    owner => root,
    group => wheel,
    mode => 755;
    "$_portsdir":
    path => "$_portsdir",
    ensure => directory,
    owner => root,
    group => wheel,
    mode => 755;
    "$_portsnap_conf":
      path => "$_portsnap_conf",
      owner => root,
      group => wheel,
      mode => 444,
      source => "${puppet_url}/dist/$_portsnap_conf";
  }

  exec {
    "portsnap cron":
      command => "$__portsnap cron",
      require => [ File["$_portsnap_conf"], File["$_portsnapdir"] ],
      timeout => 7200,
      schedule => maint;
    "portsnap fetch":
      # Use 'cron' here and not 'fetch': same result, but this defeats the interactivity test
      # pkill(1) gets around the sleep call in cron
      command => "(/bin/sleep 15 && /bin/pkill -n sleep) & ($__portsnap cron; exit 0)",
      before => Exec['portsnap cron'],
      require => [ File["$_portsnap_conf"], File["$_portsnapdir"] ],
      timeout => 7200,
      onlyif => "/bin/test `/bin/ls -1 \"$_portsnapdir\" | /usr/bin/wc -l` -eq 0";
    "portsnap extract":
      command => "$__portsnap extract",
      require => [ File["$_portsdir"], Exec['portsnap fetch'] ],
      timeout => 3600,
      onlyif => "/bin/test `/bin/ls -1 \"$_portsdir\" | /usr/bin/wc -l` -eq 0";
    "portsnap update":
      command => "$__portsnap update",
      require => [ File["$_portsdir"], Exec['portsnap cron'] ],
      schedule => maint,
      timeout => 3600,
      onlyif => "/bin/sh -c '/bin/test `/usr/bin/find \"$_portsnapdir/files\" -mtime -1 -type f | /usr/bin/head -1 | /usr/bin/wc -l` -eq 1'";
  }
}
### EXAMPLE USAGE ###
#
# class freebsd {
#   $_portsdir = $portsdir ? { '' => '/usr/ports', default => $portsdir }
# }
#
# node 'freebsd.local' {
#   include freebsd
#   include freebsd::portsnap
# }
