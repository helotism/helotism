---
layout: post
title:  "Where is $OPENSSLDIR on various distros?"
date:   2016-07-03 10:00:00 +0100
categories: [ application-physical_building-blocks ]
abstract: The package maintainer of each distribution configure OpenSSL slightly different. To potentially put certificate files in the standard location various distributions were tested for $OPENSSLDIR with the help of Docker.
---

The Helotism project started with a variety of distributions to see if the configuration management really handles a heterogenous cluster. Only the Debian-based Raspbian distribution made it at the times of Debian Wheezy necessary to consolidate on ArchLinuxARM, mainly because of the pace of systemd development. Nevertheless cross-distro config management is still not out of scope.

So when the TLS-security of the remote logging with systemd-journal-upload required a good grasp on OpenSSL, its default configuration on verious distributions was of interest. A comfortable way to quickly install some was with Docker. Then `openssl version -d` does return the directory where the package maintainer puts certificate files by default.

Here the path for various distributions:

```bash
for di in cpr/centos7 cpr/opensuseleap cpr/fedora24 \
  cpr/debianjessie cpr/archlinuxlatest; do \
    echo ${di}; docker run ${di} openssl version -d; echo ""; \
  done

cpr/centos7
OPENSSLDIR: "/etc/pki/tls"

cpr/opensuseleap
OPENSSLDIR: "/etc/ssl"

cpr/fedora24
OPENSSLDIR: "/etc/pki/tls"

cpr/debianjessie
OPENSSLDIR: "/usr/lib/ssl"

cpr/archlinuxlatest
OPENSSLDIR: "/etc/ssl"
```

