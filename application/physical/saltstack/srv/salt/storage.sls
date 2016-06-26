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
        Options = bind
        
        [Install]
        WantedBy = multi-user.target

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

