---
layout: post
title:  "Python daemon with systemd"
date:   2016-02-07 03:43:24 +0100
categories: [ application-physical_building-blocks ]
abstract: How to keep a script running as a daemon.
---


With systemd this became trivially easy, as the `.service` unit files in `/etc/systemd/system/` offer an easy way. Here is a minimal example without watchdog- or soft-fail-capabilities:

```INI
[Unit]
Description=An GPIO interrupt listener for a debounced button press to trigger an action.
After=local-fs.target

[Service]
Type=simple
ExecStartPre=/bin/bash -c 'source /opt/helotism/powersupply-env/bin/activate;'
ExecStart=/bin/bash -c 'cd /opt/helotism/powersupply-env; source bin/activate; python ./mraa_interrupt.py'

[Install]
WantedBy=multi-user.target
```

The above unit file enters a Python virtual environment that was previously deployed there. It is executed the multi-user.target has been reached. The script runs continously in a `while True:` loop, reflected by `Type=simple`.

The [blog post](http://0pointer.de/blog/projects/systemd-for-admins-3.html) or the [man page](https://www.freedesktop.org/software/systemd/man/systemd.service.html) explain all the features that are available by setting just one option.
