---
layout: post
title:  "OpenSSL With Reference to Remote Logging Via Systemd"
date:   2016-06-20 10:00:00 +0100
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


