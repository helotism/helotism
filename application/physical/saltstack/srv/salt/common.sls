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

