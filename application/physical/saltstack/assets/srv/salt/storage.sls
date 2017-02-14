mount the known partition sda2:
  file.managed:
    - name: /etc/systemd/system/mnt-sda2.mount
    - contents: |
        [Unit]
        Description = Western Digital Pi Drive 314GB
        
        [Mount]
        What = /dev/sda2
        Where = /mnt/sda2
        Type = ext4
        
        [Install]
        WantedBy = multi-user.target

bind mount a folder on sda2 to where nginx likes it:
  file.managed:
    - name: /etc/systemd/system/srv-http.mount
    - contents: |
        [Unit]
        Description = Western Digital Pi Drive 314GB
        
        [Mount]
        What = /mnt/sda2/http
        Where = /srv/http
        Type = ext4
        Options = bind
        
        [Install]
        WantedBy = multi-user.target

enabling the srv http mount unit:
  service.running:
    - name: srv-http.mount
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/srv-http.mount
    - watch:
      - file: /etc/systemd/system/srv-http.mount

automount this last partition whenever accessed:
  file.managed:
    - name: /etc/systemd/system/srv-http.automount
    - contents: |
        [Unit]
        Description = Western Digital Pi Drive 314GB
        
        [Automount]
        Where = /srv/http
        
        [Install]
        WantedBy = multi-user.target

The permissions must be correct for the remote journal mountpoint:
  file.directory:
    - name: /mnt/sda2/journal-remote
    - user: systemd-journal-remote
    - group: systemd-journal-remote
    - file_mode: 664
    - dir_mode: 2775
    - recurse:
      - user
      - group
      - mode

bind mount a folder for a systemd remote journals:
  file.managed:
    - name: /etc/systemd/system/var-log-journal-remote.mount
    - contents: |
        [Unit]
        Description = Western Digital Pi Drive 314GB
        
        [Mount]
        What = /mnt/sda2/journal-remote
        Where = /var/log/journal/remote
        Type = ext4
        Options = bind,gid=998,uid=998
        
        [Install]
        WantedBy = multi-user.target

enable the var log journal remote mount unit:
  service.running:
    - name: var-log-journal-remote.mount
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/var-log-journal-remote.mount
    - watch:
      - file: /etc/systemd/system/var-log-journal-remote.mount

automount the partition for journal-remote:
  file.managed:
    - name: /etc/systemd/system/var-log-journal-remote.automount
    - contents: |
        [Unit]
        Description = Western Digital Pi Drive 314GB
        
        [Automount]
        Where = /var/log/journal/remote
        
        [Install]
        WantedBy = multi-user.target

