#
# Then salt -G 'os:Arch ARM' state.apply proxy-cache.minion-pacman-mirrorlist
#

Create a group for the webserver user:
  group.present:
    - name: nginx
    - system: True
    - addusers:
      - nginx

And a user which is by default http on Arch Linux:
  user.present:
    - name: nginx
    - groups:
      - nginx
    - createhome: False
    - shell: /bin/false

{% for directory in ['/srv/http/localhost/htdocs', '/var/lib/nginx/tmp/proxy','/srv/http/pacman-cache', '/srv/http/apt-cache'] %}
The permissions must be correct for {{ directory }}:
  file.directory:
    - name: {{ directory }}
    - user: nginx
    - group: nginx
    - makedirs: True
    - file_mode: 664
    - dir_mode: 775
    - recurse:
      - user
      - group
      - mode
    - require:
      - pkg: nginx
{% endfor %}

Install the webserver with reverse proxy capabilities:
  pkg.installed:
    - name: nginx

Enable the nginx service:
  service.running:
    - name: nginx.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/nginx.service
    - watch:
      - pkg: nginx
      - file: /etc/nginx/nginx.conf

The unit file for nginx into the correct location:
  file.managed:
    - name: /etc/systemd/nginx.service
    - source: salt://proxy-cache/nginx.service

Completely overwriting the supplied config file:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - template: jinja
    - source: salt://proxy-cache/nginx.conf.jinja
    - user: nginx
    - group: nginx
    - mode: 640
