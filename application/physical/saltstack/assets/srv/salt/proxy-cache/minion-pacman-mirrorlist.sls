{% if grains['os_family'] == 'Arch' %}

Setting the proxy-cache as Server for the mirrorlist:
  file.managed:
    - name: /etc/pacman.d/mirrorlist
    - contents:
      - 'Server = http://{{ salt['pillar.get']('helotism:__MASTERHOSTNAME', 'axle') }}.{{ salt['pillar.get']('helotism:__FQDN', 'wheel.prdv.de') }}:8080/$arch/$repo'
      - 'Server = http://mirror.archlinuxarm.org/$arch/$repo'

{% endif %}
