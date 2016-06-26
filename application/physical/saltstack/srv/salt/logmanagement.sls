Strangely missing dependency on Arch Linux:
  pkg.installed:
    - name: libmicrohttpd

#To later use python-systemd bindings
Version 0.14 or higher is needed of PyOpenSSL:
  pkg.installed:
    - name: python2-pyopenssl

trusted certificates chain file:
  file.managed:
    - name: /etc/ssl/helotism-ca-chained-public-certs.cert.pem
    - contents_pillar: files:helotism-ca-chained-public-certs.cert.pem

this host s private key file:
  file.managed:
    - name: /etc/ssl/private/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.key.pem
    - contents_pillar: files:{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.key.pem

this host s public certificate file:
  file.managed:
    - name: /etc/ssl/certs/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.cert.pem
    - contents_pillar: files:{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.cert.pem

{% if grains['id'] == salt['pillar.get']('helotism:__MASTERHOSTNAME', 'axle') %}
the config file for journal-remote:
  file.managed:
    - name: /etc/systemd/journal-remote.conf
    - contents: |
        [Remote]
        #master
        ServerKeyFile=/etc/ssl/private/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.key.pem
        ServerCertificateFile=/etc/ssl/certs/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.cert.pem
        TrustedCertificateFile=/etc/ssl/helotism-ca-chained-public-certs.cert.pem

enable the systemd service for the receiving journal-remote:
  service.running:
    - name: systemd-journal-remote.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/journal-remote.conf 
    - watch:
      - file: /etc/systemd/journal-remote.conf 

{% else %}
nothing to configure here:
  file.absent:
    - name: /etc/systemd/journal-remote.conf
{% endif %}

the config file for journal-upload:
  file.managed:
    - name: /etc/systemd/journal-upload.conf
    - contents: |
        [Upload]
        #URL=https://axle.wheel.prdv.de
        URL=https://{{ salt['pillar.get']('helotism:__MASTERHOSTNAME', 'axle') }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}
        ServerKeyFile=/etc/ssl/private/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.key.pem
        ServerCertificateFile=/etc/ssl/certs/{{ grains.id }}.{{ salt['pillar.get']('helotism:__FQDNNAME', 'wheel.prdv.de') }}.cert.pem
        TrustedCertificateFile=/etc/ssl/helotism-ca-chained-public-certs.cert.pem

enable the systemd service for journal-upload:
  service.running:
    - name: systemd-journal-upload.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/journal-upload.conf 
    - watch:
      - file: /etc/systemd/journal-upload.conf 
