class freebsd {
  $_portsdir = $portsdir ? { '' => '/usr/ports', default => $portsdir }
  
  define periodic_conf($value) {
    shell_config {  "periodic_conf_${name}":
      file => '/etc/periodic.conf',
      key => $name,
      value => $value
    }
  }

  define rc_conf_local($value) {
    shell_config { "rc_conf_local_${name}":
      file => "/etc/rc.conf.local",
      key => $name,
      value => $value;
    }
  }

  ### EXAMPLE
  #
  #periodic_conf {
  #  daily_show_badconfig: value => YES;
  #  daily_clean_tmps_enable: value => YES;
  #  weekly_noid_enable: value => YES;
  #  weekly_status_pkg_enable: value => YES;
  #}
  #
  #rc_conf_local {
  #  inetd_flags: value => "-wW -a $ipaddress";
  #}

  define ports_conf($key, $value) {
    shell_config {
      "port_${name}_rc_conf_${key}":
        file => "/etc/rc.conf.d/${name}",
        key => $key,
        value => $value;
    }
  }

  ### EXAMPLE
  #
  #node 'freebsd.local' {
  #  include freebsd-mtree
  #  include ports-puppet
  #}
  #
  ## Only needed to create /etc/rc.conf.d:
  #class freebsd-mtree {
  #  file {
  #    "/etc/rc.conf.d":
  #      ensure => directory.
  #      owner => root,
  #      group => wheel,
  #      mode => 755;
  #  }
  #}
  #
  #class ports-puppet {
  #...
  #  file { "/usr/local/etc/puppet/puppet.conf":
  #    alias => "puppet.conf",
  #    path => "/usr/local/etc/puppet/puppet.conf",
  #    owner => root,
  #    group => wheel,
  #    mode => 444,
  #    source => "...";
  #  }
  #
  #  exec { "puppetd-restart":
  #    command => "/usr/local/etc/rc.d/puppetd restart",
  #    subscribe => File["puppetd.conf"],
  #    refreshonly => true,
  #  }
  #
  #  ports_conf {
  #    puppetd:       key => puppetd_enable,       value => YES;
  #    puppetmasterd: key => puppetmasterd_enable, value => YES;
  #  }
  #}
  
  define shell_config($file, $key, $value, $ensure = 'present') {
    case $ensure {
      default: { err ( "unknown ensure value ${ensure}" ) }
      present: {
        augeas { "shell_config_$name":
          lens    => 'Shellvars.lns',
          incl    => $file,
          changes => "set /files/$file/$key '\"$value\"'",
        }
      }
      absent: {
        augeas { "shell_config_$name":
          lens    => 'Shellvars.lns',
          incl    => $file,
          changes => "remove /files/$file/$key",
        }
      }
    }
  }
}
