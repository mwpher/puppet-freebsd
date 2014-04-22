class freebsd {
  $_portsdir = $portsdir ? { '' => '/usr/ports', default => $portsdir }
}
