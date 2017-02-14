making the i2c-tools programs a requirement:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: sys-apps/i2c-tools
    {% else %}
    - name: i2c-tools
    {% endif %}

Adding a config line about device_tree at the end:
  file.append:
    - name: /boot/config.txt
    - text: device_tree=bcm2709-rpi-2-b.dtb
#   - text: device_tree=bcm2710-rpi-3-b.dtb

Adding a config line about dtparam at the end:
  file.append:
    - name: /boot/config.txt
    - text: dtparam=i2c

Adding modules to autoload:
  file.append:
    - name: /etc/modules-load.d/raspberrypi.conf
    - text: |
        i2c-dev
        i2c-bcm2708

as we are here the GPU could be reduced:
  file.line:
    - name: /boot/config.txt
    - match: gpu_mem=
    - content: gpu_mem=16
    - mode: Replace

the service file:
  file.managed:
    - name: /etc/systemd/system/helotism-i2c-rtc.service
    - contents: |
        [Unit]
        Description=RTC clock via I2C
        After=systemd-modules-load.service
        Conflicts=shutdown.target
        #
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=/bin/bash -c 'echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device; sleep 4;  hwclock -s' 
        ExecStop=/bin/bash -c 'echo 0x68 > /sys/class/i2c-adapter/i2c-1/delete_device'
        TimeoutSec=0
        [Install]
        WantedBy=time-sync.target

Enable the i2c-rtc service:
  service.running:
    - name: helotism-i2c-rtc.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/helotism-i2c-rtc.service
    - watch:
      - file: /etc/systemd/system/helotism-i2c-rtc.service

setting the timezone:
  cmd.run:
    - name: "timedatectl set-timezone 'Europe/Berlin'"
