The inotify beacon requires Pyinotify:
  pkg.installed:
    - name: python2-inotify

/etc/salt/master.d/reactor.conf:
  file.prepend:
    - text:
      - "reactor:"
