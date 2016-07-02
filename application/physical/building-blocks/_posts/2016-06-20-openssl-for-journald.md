---
layout: post
title:  "OpenSSL With Reference to Remote Logging Via Systemd"
date:   2099-06-20 10:00:00 +0100
categories: [ application-physical_building-blocks ]
---


Recommended Reading


Naming conventions:
http://serverfault.com/a/9717
.csr
.pem
.key
.pkcs12 .pfx .p12
.der


https://www.freedesktop.org/software/systemd/man/systemd-journal-remote.html
https://www.freedesktop.org/software/systemd/man/journal-remote.conf.html
https://www.freedesktop.org/software/systemd/man/systemd-journal-upload.html

https://www.madboa.com/geek/openssl/
https://wiki.openssl.org/index.php/Command_Line_Utilities
http://www.flatmtn.com/article/setting-openssl-create-certificates
https://www.openssl.org/docs/manmaster/apps/req.html
http://www.heimpold.de/mhei/mini-howto-zertifikaterstellung.htm
https://jamielinux.com/docs/openssl-certificate-authority/index.html

https://fedoraproject.org/wiki/Changes/Remote_Journal_Logging

https://docs.google.com/document/pub?id=1IC9yOXj7j6cdLLxWEBAGRL6wl97tFxgjLUEHIX3MSTs
https://www.loggly.com/blog/why-journald/


openssl req -subj '/C=DE/ST=Hessen/L=Rittershausen/O=PRDV/OU=IT/CN=localhost' -x509 -nodes -days 365 -sha256   -newkey rsa:2048 -keyout mycert.key -out mycert.crt

openssl req -subj '/C=DE/ST=Hessen/L=Rittershausen/O=PRDV/OU=IT/CN=localhost' -x509 -nodes -days 365 -sha256   -newkey rsa:2048 -keyout mycert.pem -out mycert.pem

openssl s_server -cert mycert.crt -key mycert.key -www

openssl s_server -cert mycert.pem -www

openssl s_server -cert mycert.crt -key mycert.key -WWW

-accept 4443

openssl s_client -connect localhost:4433



echo "test" > test.html
openssl s_server -cert mycert.pem -WWW
curl --cacert mycert.pem --cert mycert.pem --key mycert.pem https://localhost:4433/test.html
curl --cacert mycert.pem  https://localhost:4433/test.html
curl --cacert mycert.pem --cert mycert.crt --key mycert.key https://localhost:4433/test.html




https://www.freedesktop.org/software/systemd/man/systemd-journal-upload.html


```bash
$ openssl version -d
OPENSSLDIR: "/usr/ssl"
```

$ openssl version -a
OpenSSL 1.0.2h  3 May 2016
built on: reproducible build, date unspecified
platform: Cygwin
options:  bn(64,32) md2(int) rc4(8x,mmx) des(ptr,risc1,16,long) idea(int) blowfish(idx) 
compiler: gcc -I. -I.. -I../include  -D_WINDLL -DOPENSSL_PIC -DZLIB -DOPENSSL_THREADS  -DDSO_DLFCN -DHAVE_DLFCN_H -ggdb -O2 -pipe -Wimplicit-function-declaration -fdebug-prefix-map=/usr/src/ports/openssl/openssl-1.0.2h-1.i686/build=/usr/src/debug/openssl-1.0.2h-1 -fdebug-prefix-map=/usr/src/ports/openssl/openssl-1.0.2h-1.i686/src/openssl-1.0.2h=/usr/src/debug/openssl-1.0.2h-1 -DTERMIOS -DL_ENDIAN -fomit-frame-pointer -O3 -march=i686 -Wall -DOPENSSL_BN_ASM_PART_WORDS -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DMD5_ASM -DRMD160_ASM -DAES_ASM -DVPAES_ASM -DWHIRLPOOL_ASM -DGHASH_ASM
OPENSSLDIR: "/usr/ssl"




d=$(openssl version -d); d=${d/:/=}; d=${d/ /}; eval $d; echo $OPENSSLDIR

cat $OPENSSLDIR/openssl.cnf
#make an own



Validity
http://security.stackexchange.com/questions/31607/how-to-set-not-before-value-to-past-when-creating-certificate-request
openssl ca -batch -config ca.conf -startdate 20160101000000 -enddate 20251231235959 -notext -in $SERVER.csr -out $SERVER.pem





$ docker  pull centos:7
7: Pulling from library/centos

a3ed95caeb02: Pull complete
da71393503ec: Pull complete
Digest: sha256:a9237ff42b09cc6f610bab60a36df913ef326178a92f3b61631331867178f982
Status: Downloaded newer image for centos:7

docker commit -m "Installed openssl." -a 'Christian Prior' 8517f51f1e41 cpr/centos7

docker run cpr/centos7 openssl version -d
OPENSSLDIR: "/etc/pki/tls"






cpr@T500-2016:~$ docker pull opensuse:leap
leap: Pulling from library/opensuse

Digest: sha256:7cbe1898a4612cdea9dd03770f4f1e3e95393412313a9a40c61d8c0144edba92
Status: Image is up to date for opensuse:leap
cpr@T500-2016:~$ docker run opensuse:leap openssl version -d
OPENSSLDIR: "/etc/ssl"



docker pull fedora:24
24: Pulling from library/fedora

7c91a140e7a1: Pull complete
Digest: sha256:a97914edb6ba15deb5c5acf87bd6bd5b6b0408c96f48a5cbd450b5b04509bb7d
Status: Downloaded newer image for fedora:24

docker run fedora:24 openssl version -d
Yum command has been deprecated, redirecting to '/usr/bin/dnf install -y openssl'.

docker commit -m "Installed openssl." -a 'Christian Prior' $(docker ps -l -q) cpr/fedora24
sha256:ce5733e6c3c161ead18a28d1222d98320d0e34c09c6fcc483dc295d2d66f7daf
cpr@T500-2016:~$ docker run cpr/fedora24 openssl version -d
OPENSSLDIR: "/etc/pki/tls"



docker pull debian:jessie
jessie: Pulling from library/debian

Digest: sha256:8b1fc3a7a55c42e3445155b2f8f40c55de5f8bc8012992b26b570530c4bded9e
Status: Image is up to date for debian:jessie

docker run debian:jessie /bin/bash -c "apt-get update && apt-get upgrade && apt-get --assume-yes  install openssl"

docker commit -m "Installed openssl." -a 'Christian Prior' $(docker ps -l -q) cpr/debianjessie
sha256:8d1c299156874ca27aa55875816a44db78f1efdc73b3d9bdbb3ee2d42155550e

docker run cpr/debianjessie openssl version -d
OPENSSLDIR: "/usr/lib/ssl"




cpr@T500-2016:~$ docker pull base/archlinux
Using default tag: latest
latest: Pulling from base/archlinux

a3ed95caeb02: Already exists
80ab36053684: Already exists
Digest: sha256:7905fad7578b9852999935fb0ba9c32fe16cece9e4d1d742a34f55ce9cebdfd1
Status: Image is up to date for base/archlinux:latest
cpr@T500-2016:~$ docker run base/archlinux:latest openssl version -d
OPENSSLDIR: "/etc/ssl"
cpr@T500-2016:~$ 



docker pull gentoo/portage
docker pull gentoo/stage3-amd64
docker create -v /usr/portage --name portage gentoo/portage
docker run --volumes-from portage -it gentoo/stage3-amd64 /bin/bash -c "openssl version -d"
OPENSSLDIR: "/etc/ssl"









for di in cpr/centos7 cpr/opensuseleap cpr/fedora24 cpr/debianjessie cpr/archlinuxlatest; do echo ${di}; docker run ${di} openssl version -d; echo ""; done
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




[root@axle ~]# systemd-journal-upload --help
-bash: systemd-journal-upload: command not found
[root@axle ~]# /usr/lib/systemd/systemd-journal-upload --help
systemd-journal-upload -u URL {FILE|-}...

Upload journal events to a remote server.

  -h --help                 Show this help
     --version              Show package version
  -u --url=URL              Upload to this address (default port 19532)
     --key=FILENAME         Specify key in PEM format (default:
                            "/etc/ssl/private/journal-upload.pem")
     --cert=FILENAME        Specify certificate in PEM format (default:
                            "/etc/ssl/certs/journal-upload.pem")
     --trust=FILENAME|all   Specify CA certificate or disable checking (default:
                            "/etc/ssl/ca/trusted.pem")
     --system               Use the system journal
     --user                 Use the user journal for the current user
  -m --merge                Use  all available journals
  -M --machine=CONTAINER    Operate on local container
  -D --directory=PATH       Use journal files from directory
     --file=PATH            Use this journal file
     --cursor=CURSOR        Start at the specified cursor
     --after-cursor=CURSOR  Start after the specified cursor
     --follow[=BOOL]        Do [not] wait for input
     --save-state[=FILE]    Save uploaded cursors (default 
                            /var/lib/systemd/journal-upload/state)
  -h --help                 Show this help and exit
     --version              Print version string and exit



[root@axle ~]# /usr/lib/systemd/systemd-journal-remote --listen-https=axle.wh
eel.prdv.de 
/usr/lib/systemd/systemd-journal-remote: error while loading shared libraries: libmicrohttpd.so.12: cannot open shared object file: No such file or directory


Jun 13 00:11:26 axle.wheel.prdv.de systemd[1]: systemd-journal-remote.service: Failed with result 'exit-code'.
[root@axle ~]# systemctl daemon-reload
[root@axle ~]# systemctl restart systemd-journal-remote.service
[root@axle ~]# systemctl status systemd-journal-remote.service
� systemd-journal-remote.service - Journal Remote Sink Service
   Loaded: loaded (/usr/lib/systemd/system/systemd-journal-remote.service; indirect; vendor preset: disabled)
   Active: failed (Result: exit-code) since Mon 2016-06-13 00:11:57 UTC; 1s ago
     Docs: man:systemd-journal-remote(8)
           man:journal-remote.conf(5)
  Process: 11413 ExecStart=/usr/lib/systemd/systemd-journal-remote --listen-https=-3 --output=/var/log/journal/remote/ (code=exited, status=127)
 Main PID: 11413 (code=exited, status=127)

Jun 13 00:11:57 axle.wheel.prdv.de systemd[1]: Started Journal Remote Sink Service.
Jun 13 00:11:57 axle.wheel.prdv.de systemd[1]: systemd-journal-remote.service: Main process exited, code=exited, status=127/n/a
Jun 13 00:11:57 axle.wheel.prdv.de systemd[1]: systemd-journal-remote.service: Unit entered failed state.
Jun 13 00:11:57 axle.wheel.prdv.de systemd[1]: systemd-journal-remote.service: Failed with result 'exit-code'.
[root@axle ~]# vim /etc/systemd/journal-remote.conf



for h in axle spoke0{1,2,3,4} cog0{1,2,3,4}; do mkdir -p /mnt/sda2/ext_file_pillar/hosts/${h}/files/ ; cp /mnt/sda2/ca/helotism-intermediate-ca/private-keys/${h}.wheel.prdv.de.key.pem /mnt/sda2/ext_file_pillar/hosts/${h}/files/; cp /mnt/sda2/ca/helotism-intermediate-ca/public-certs/${h}.wheel.prdv.de.cert.pem /mnt/sda2/ext_file_pillar/hosts/${h}/files/; cp /mnt/sda2/ca/helotism-intermediate-ca/public-certs/helotism-ca-chained-public-certs.cert.pem /mnt/sda2/ext_file_pillar/hosts/${h}/files/; done

mkdir /mnt/sda2/ext_file_pillar
cat /etc/salt/master.d/90_ext_pillar.conf ext_pillar:
  - git:
    - master https://github.com/helotism/helotism.git:
      - root: application/physical/saltstack/srv/pillar
  - file_tree:
      root_dir: /mnt/sda2/ext_file_pillar
      follow_dir_links: False
      keep_newline: True

systemctl restart salt-master.service


salt '*' saltutil.refresh_pillar


With Python returning valid dates from certificate file

https://pyopenssl.readthedocs.io/en/latest/api/crypto.html
http://nullege.com/codes/search/OpenSSL.crypto.load_certificate
http://blog.tunnelshade.in/2013/06/sign-using-pyopenssl.html
http://www.yothenberg.com/validate-x509-certificate-in-python/

```
#pip install pyopenssl
from OpenSSL import crypto

loaded_host_certificate = crypto.load_certificate(crypto.FILETYPE_PEM, open("/etc/ssl/certs/axle.wheel.prdv.de.cert.pem").read())

print loaded_host_certificate.get_notBefore()
#20160101000000Z

print loaded_host_certificate.get_notAfter()
#20180612204409Z
```



```
from OpenSSL import crypto
host_cert=open("/etc/ssl/certs/axle.wheel.prdv.de.cert.pem").read()
loaded_host_certificate = crypto.load_certificate(crypto.FILETYPE_PEM, host_cert)
store = crypto.X509Store()
store.add_cert(crypto.load_certificate(crypto.FILETYPE_PEM, root_cert))
store.add_cert(crypto.load_certificate(crypto.FILETYPE_PEM, intermediate_cert))

store_context = crypto.X509StoreContext(store, loaded_host_certificate)
retval = store_context.verify_certificate()
print(retval)
None
```
