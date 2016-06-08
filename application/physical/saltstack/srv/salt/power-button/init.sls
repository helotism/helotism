
pacman -S --needed --noconfirm net-tools base-devel:
  cmd.run

python2-pip:
  pkg.installed

python2-virtualenv:
  pkg.installed:
    - require:
      - pkg: python2-pip
    - require_in:
      - virtualenv: /opt/helotism/power-button_venv

mypipupdate:
  cmd.run:
    - name: 'pip2 install --upgrade pip'
    - require_in:
      - pkg: python2-virtualenv

setup the virtual python environment:
  virtualenv.managed:
    - name: /opt/helotism/power-button_venv
    - system_site_packages: False
    - pip_pkgs:
      - nodeenv
    - requirements: salt:///power-button/requirements.txt


Finally the Python script itself:
  file.managed:
    - name: /opt/helotism/power-button_venv/app.py
    - template: jinja
    - context:
      delayedhost: {{ salt['pillar.get']('helotism:__MASTERHOSTNAME:', 'axle') }}
    - user: root
    - group: root
    - mode: 744
    - source: salt:///power-button/app.py.jinja
    - require:
      - virtualenv: /opt/helotism/power-button_venv

enable the systemd service:
  service.running:
    - name: helotism-power-button.service
    - enable: true
    - provider: systemd
    - require:
      - file: /etc/systemd/system/helotism-power-button.service

place the systemd unit file in the correct folder:
  file.managed:
    - name: /etc/systemd/system/helotism-power-button.service
    - source: salt:///power-button/helotism-power-button.service.sample
