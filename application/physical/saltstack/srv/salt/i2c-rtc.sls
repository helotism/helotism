making the i2c-tools programs a requirement:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: sys-apps/i2c-tools
    {% else %}
    - name: i2c-tools
    {% endif %}

loading the devicetree:
  file.line:
    - name: /boot/config.txt
    - content: device_tree=bcm2710-rpi-3-b.dtb
    - mode: Replace

setting the sevicetree params:
  file.line:
    - name: /boot/config.txt
    - content: dtparam=i2c
    - mode: Replace

as we are here the GPU could be reduced:
  file.line:
    - name: /boot/config.txt
    - content: gpu_mem=16
    - mode: Replace

the service file:
  file.managed:
    - name: /etc/systemd/system/i2c-rtc.service
    - contents: |
        [Unit]
        Description=RTC clock via I2C
        After=systemd-modules-load.service
        Conflicts=shutdown.target
        #RequiresMountsFor=/dev/rtc
        [Service]
        Type=oneshot
        ExecStart=/bin/bash -c 'echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device; hwclock -s' 
        TimeoutSec=0
        [Install]
        WantedBy=time-sync.target

setting the timezone:
  cmd.run:
    - name: "timedatectl set-timezone 'Europe/Berlin'"
