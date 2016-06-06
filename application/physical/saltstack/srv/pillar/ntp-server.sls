ntp:
  ng:
    settings:
      ntpd: True
      ntp_conf: 
        server: ['127.127.1.1', '0.de.pool.ntp.org', '1.de.pool.ntp.org', '2.de.pool.ntp.org', '3.de.pool.ntp.org']
        restrict: ['default nomodify nopeer noquery', '127.0.0.1', '::1', '10.0.0.0 mask 255.0.0.0 nomodify nopeer notrap' ]
#        restrict: ['default nomodify nopeer noquery', '127.0.0.1', '::1', '10.0.0.0 mask 255.0.0.0 nomodify nopeer notrap', '{{ salt['pillar.get']('foo:bar:baz', 'qux') }}']
        fudge: ['127.127.1.1 stratum 12']
        driftfile: ['/var/lib/ntp/ntp.drift']
