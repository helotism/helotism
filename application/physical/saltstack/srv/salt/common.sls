vim:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-editors/vim
    {% else %}
    - name: vim
    {% endif %}

screen:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-misc/screen
    {% else %}
    - name: screen
    {% endif %}

dnsutils:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: net-dns/bind-tools
    {% elif grains['os'] == 'Arch ARM' %}
    - name: bind-tools
    {% else %}
    - name: dnsutils
    {% endif %}

sudo:
  pkg.installed:
    {% if grains['os'] == 'Gentoo' %}
    - name: app-admin/sudo
    {% else %}
    - name: sudo
    {% endif %}

enabling spi:
  file.line:
    - name: /boot/config.txt
    - content: dtparam=spi=on
    - mode: Replace

pip2:
  pkg.installed:
    {% if grains['os'] == 'Gentoo_____' %}
    - name: net-dns/bind-tools
    {% elif grains['os'] == 'Arch ARM' %}
    - name: python2-pip
    {% else %}
    - name: python2-pip
    {% endif %}

virtualenv2:
  pkg.installed:
    {% if grains['os'] == 'Gentoo_____' %}
    - name: net-dns/bind-tools
    {% elif grains['os'] == 'Arch ARM' %}
    - name: python2-virtualenv
    {% else %}
    - name: python2-virtualenv
    {% endif %}

some dependencies on Arch Linux ARM:
  cmd.run:
    - name: pacman -S --needed --noconfirm net-tools base-devel:

ipython for Python2:
  pkg.installed:
    {% if grains['os'] == 'Gentoo_____' %}
    - name: net-dns/bind-tools
    {% elif grains['os'] == 'Arch ARM' %}
    - name: ipython2
    {% else %}
    - name: ipython2
    {% endif %}
