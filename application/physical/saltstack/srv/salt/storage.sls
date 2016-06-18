#This is a very crude and rude state as /dev/sda2 is hardcoded

Mounting /dev/sda2 as ext4 a default fshs:
  file.managed:
    - name: /etc/systemd/system/mnt-sda2.mount
    - source: salt:///storage/mnt-sda2.mount.sample

bind-mounting a subdirectory from /dev/sda2 to an nginx location:
  file.managed:
    - name: /etc/systemd/system/srv-http.mount
    - source: salt:///storage/srv-http.mount.sample


place the systemd unit file in the correct folder:
  file.managed:
    - name: /etc/systemd/system/srv-http.automount
    - source: salt:///storage/srv-http.automount.sample
