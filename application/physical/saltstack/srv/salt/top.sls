base:

  '*':
    - common
    - users
    - helotism
    - salt-minion

#salt '*' grains.append key val
#salt '*' grains.remove key val

  'roles:dhcp-server':
    - match: grain
    - dhcp-server

  'roles:salt-master':
    - match: grain
    - salt-master

  'roles:i2c-rtc':
    - match: grain
    - i2c-rtc

  'roles:ntp-server':
    - match: grain
    - ntp-server

  'roles:proxy-cache':
    - match: grain
    - proxy-cache

  'roles:network-router':
    - match: grain
    - network-router

  'roles:power-button':
    - match: grain
    - power-button

