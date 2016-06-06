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

  'roles:dns-server':
    - match: grain
    - dns-server

  'roles:ntp-server':
    - match: grain
    - ntp-server

  'roles:proxy-cache':
    - match: grain
    - proxy-cache

  'roles:network-router':
    - match: grain
    - network-router

  'roles:power-switch':
    - match: grain
    - power-switch

