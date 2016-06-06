---
layout: post
title:  "Python daemon with systemd"
date:   2016-02-07 03:43:24 +0100
categories: [ application-physical_building-blocks ]
---


How to keep a Python script running.

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

Foo.
