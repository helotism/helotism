---
layout: post
title:  "A Basic Saltstack Proxy Minion"
date:   2017-03-19 15:00:00 +0100
categories: [ application-physical_building-blocks, saltstack ]
abstract: How to code a basic proxy minion on Saltstack.
---

Saltstack proxy minions are minions that cannot run a full Python minion client and are also not accesible as a salt-ssh minion, but provide some other means of communication with e.g. a REST API.

This article describes a minimal code setup to write on own proxy minion module. This will be such a minimal example that even no other device is connected. But rather some syntactically valid files are being produced.

To actually connect to some other device is up to the custom implenentation of such a proxy module. In its basic form there is "just" another minion process running on a "real minion".

![Saltststack Proxy Minion](./images/saltstack-proyminion-orbital.png)
*Illustration of two proxy minions each on a "real minion"*

A proxy minion is a process that runs on a standard minion. It is a lightweight wrapper around an execution module. So it is necessary to write such an execution minion first.

The location of such modules (both execution module as well as proxy module) is typically in /srv/salt/_modules and /srv/salt/_proxy but its exact location can be found with `python2 -c 'import salt.config; master_opts = salt.config.client_config("/etc/salt/master"); print(master_opts["file_roots"])'`.

Similarly the current Salt minion's ID can be determined with `python2 -c 'import salt.config; minion_opts = salt.config.salt.config.minion_config("/etc/salt/minion"); print(minion_opts["id"])'`.

There is some thorough information available in the Saltstack docs and the following reading is mandatory to continue:

Writing Execution Modules https://docs.saltstack.com/en/latest/ref/modules/
On that page especially the part about __virtualname__ https://docs.saltstack.com/en/latest/ref/modules/#virtualname and __virtual__ function https://docs.saltstack.com/en/latest/ref/modules/#virtual-function

ToDo: proxy minion docs
The __proxyenabled__ directive https://docs.saltstack.com/en/latest/topics/proxyminion/index.html#the-proxyenabled-directive

ToDo: sync docs

To write a basic proxy module that does not do anything but syntactically work these are the steps to do and where to do:

1. [master] write an execution module at the proper filesystem location
2. [master] synchronize this new code into Saltstack
3. [master] call execution module functions as a test
4. [master] write a proxy minion wrapper
5. [master] synchronize this new code into Saltstack
6. [master] configure a proxy minion
7. [minion] start a proxy minion manually
8. [master] accept a new proxy minion
9. [master] call proxy minion functions

ToDo: Check if callable from minion

This basic proxy module shall be named foobar and  will contain a function `proxy_echo` that takes a text parameter. The execution module part will echo this parameter, then pass it into the proxy module which also echoes it:

```bash
$ sudo salt 'proxydemo' foobar.proxy_echo myfoo
proxydemo:
    myfoo...
    >>>myfoo
```

The previous code snippet with `salt.config` should have returned `/srv/salt` as part of `master_opts["file_roots"]` (maybe amongst others). So a directory `/srv/salt/_modules` will be recognized by Saltstack as a location for execution modules.

Which means a skeleton of an execution module could look like this, located in `/srv/salt/_modules/foobar.py`:

```Python
'''
Provide an execution module 'foobar'
'''

from __future__ import absolute_import

'''A convention for the docu generation'''
__virtualname__ = 'helotism'


def __virtual__():
    '''The virtual__ function is a kind of a gatekeeper
    where return False might be called if some requirements are not met.'''
    return __virtualname__

def true():
    '''A small test function
    '''
    return True
```

This code is only a minor bit more than the absoute minimal example because the function `true()` allows a basic test soon after.

With this code in `/srv/salt/_modules/` it needs to be synchronized into Saltstack with the "real" minion as the target:

ToDo: check if minion or master is the target

```bash
$ sudo salt 'saltminion' saltutil.sync_modules
   saltminion:
    - modules.foobar
```

After this a new execution module is available to the "real minion" and can be called like all execution modules
- from the master with `salt`
- from the minion with `salt-call --local`

Here the example call from the Saltmaster:
```bash
$ sudo salt 'saltminion' helotism.true           saltminion:
    True
```

Or from the "real minion":
```bash
$ sudo salt-call --local helotism.true           saltminion:
    True
```

This solves the steps 1. to 3. (write an execution module at the proper filesystem location, synchronize this new code into Saltstack, call execution module functions as a test).

A minor addition is a starting point for the proxy minion wrapper module:

```Python
def proxy_echo(text = 'foo'):
    ret = text
    #ret = ret + '...\n' + __proxy__['foobar.proxy_echo'](text)
    return ret
```

Added to `/srv/salt/_modules/foobar.py` it leaves the call to the proxy minion module commented out because that code does not exist yet but needs to be placed in `/srv/salt/_proxy/foobar.py`.

But before that can be done each change in the codebase needs a manual synchronization:

ToDo: check if minion or master is the target

```bash
$ sudo salt 'saltminion' saltutil.sync_modules   saltminion:
    - modules.foobar
```

For the moment `sync_modules` suffices as this synchronizes the execution modules. In the next step `sync_all` is the better variant.

However, the following calls should already work:

```Python
$ sudo salt 'saltminion' foobar.proxy_echo baz 
local:
    baz...
$ sudo salt-call --local foobar.proxy_echo baz 
local:
    baz...
```

Instead of continuing with the proxy minion code this is a good moment to add a few debugging options first, namely logging and running the `salt-master` in the foreground.

Access to the logging instances is provided by adding ar the beginning of the execution modules the two lines:

```Python
import logging
log = logging.getLogger(__file__)
```

Within the functions log messages are then added per loglevel like this:

```Python
log.info('An informational log message')
log.warning('A warning witten into the log message.')
log.error('An error occurred.')
```

The loglevels are named critical > error > warning > info > profile > debug > trace > garbage > all. A page about Saltstack's logging behaviour is included in the docs at https://docs.saltstack.com/en/latest/ref/configuration/logging/ .

Such log entries are then written into the default logfile `/var/log/salt/master` or `/var/log/salt/minion`. To double-check if any location was changed these two snippets will return some useful logging configuration output. If `log_level_logfile` is not set, a default of `info` is used. The setting `log_level` is used for the foreground output on the console.

For the master: `python2 -c 'import salt.config; master_opts = salt.config.client_config("/etc/salt/master"); master_opts_extract = dict((k, master_opts[k]) for k in ("log_file", "log_level", "log_level_logfile")); print(master_opts_extract)'`

For the minion: `python2 -c 'import salt.config; minion_opts = salt.config.minion_config("/etc/salt/minion"); minion_opts_extract = dict((k, minion_opts[k]) for k in ("log_file", "log_level", "log_level_logfile")); print(minion_opts_extract)'`

ToDo: check which logfile to tail



```bash
$ sudo systemctl stop salt-master
$ sudo salt-master -l debug
```

To then start writing the proxy module in `/srv/salt/_proxy/foobar.py` again some skeleton code is needed:

```Python
'''
Provide an proxy module
'''

from __future__ import absolute_import

import salt.utils

'''A convention for the docu generation'''
__virtualname__ = 'helotism'
''' Proxy (and grains) modules need to be told which proxy they work with.'''
__proxyenabled__ = ['helotism']

GRAINS_CACHE = {}

def __virtual__():
    '''The virtual__ function is a kind of a gatekeeper
    where return False might be returned if some requirements are not met.'''
    return __virtualname__

def init(opts=None):
    return True
def shutdown(opts):
    return True
def grains():
    return GRAINS_CACHE
def initialized():
    return True
```

The above code contains the needed functions `init()`, `shutdown()`, `initialized()` and `grains()`, `salt-proxy` will complain if any of these is missing.

Additionally the function which is called from the earlier remote execution module with `__proxy__['foobar.proxy_echo'](text)` is also added to the file. It only contains some basic logic to later show the difference between the calls in both modules.

```Python
def proxy_echo(text):
    if text in ['foo']:
        ret = '...bar'
    else:
        ret = '>>>' + text
    return ret
```

The above snippet shows how proxy modules are a lightweight wrapper around execution modules.

This new file also needs to be made known within Saltstack right away with:


```bash
$ sudo salt 'saltminion' saltutil.sync_all
saltminion:
    ----------
    beacons:
    engines:
    grains:
    log_handlers:
    modules:
    output:
    proxymodules:
        - proxy.foobar
    renderers:
    returners:
    sdb:
    states:
    utils:
```

The output now shows that a proxy module is synchronized. After each change to the files this comman needs to be called, otherwise a complete salt-master restart was (unnecessarily) necessary.

Proxy minions are configured in Saltstack through the `pillar` system. The `pillar` data structures are according to https://docs.saltstack.com/en/latest/topics/tutorials/pillar.html not only meant for vault-like sensitive data, but also for any minion configuration, variables and arbitrary key-value pairs. The following proxy-minion configuration is an example of such other data.

As usual, the pillar `top.sls` file contains minion IDs and their config files. So a basic `top.sls` might look like:

```YAML
base:
  proxydemo:
    - proxydemoconfig
```

And then in proxydemoconfig.sls:
```YAML
proxy:
  proxytype: foobar
```

According to the pillar system as *minion configuration* the minion with the ID `proxydemo` (which does not exist yet!) has its own config file, and in there under the `proxy` key a `proxytype` is configured. The value `foobar` refers return value of __virtual__(), which happens to be __virtualname__ in the above code example.

ToDo: check

As after any changes to pillar data the cache needs to be refreshed:

```bash
sudo salt '*' saltutil.refresh_pillar
saltminion:
    True
```

In this example the proxy minion lives on a minion with the ID `saltminion`. Assuming this is the hostname of the minion some steps are performed on `saltminion`, e.g. by `ssh $USER@saltminion`:

It is now the next step to start the proxy-minion process. For debugging and troubleshooting purposes this article starts the proxy-minion on the console in foreground. The docs also describes the method of starting by a *beacon* https://docs.saltstack.com/en/latest/topics/proxyminion/beacon.html .

ToDo: 

As usual, the documentation chapter "Command Line Reference" contains a page for this executable https://docs.saltstack.com/en/latest/ref/cli/salt-proxy.html


```bash
sudo salt-proxy --proxyid=proxydemo -l debug
```

Here the salt proxy is /not/ started as daemon (would take the parameter -d) and its console output log level is set to debug.

```bash
[DEBUG   ] Connecting to master. Attempt 1 of 1
[DEBUG   ] Initializing new AsyncAuth for ('/etc/salt/pki/minion', 'proxydemo', 'tcp://127.0.0.1:4506')
...
[ERROR   ] The Salt Master has cached the public key for this node, this salt minion will wait for 10 seconds before attempting to re-authenticate
[INFO    ] Waiting 10 seconds before retry.
```

As with each minion contacing the Saltmaster for the first time, and the proxy minion does not differ in any ways from a standard minion, the (proxy) minion needs to be accepted by the master (and on the master itself, not on the ssh'd-into minion -- if it differs like in this example:

```bash
$ sudo salt-key -L
Accepted Keys:
#snip
Denied Keys:
Unaccepted Keys:
proxydemo
Rejected Keys:

$ sudo salt-key -y -a proxydemo
The following keys are going to be accepted:
Unaccepted Keys:
proxydemo
Key for minion proxydemo accepted.
```

Now if all went well the proxy minion code can be called from the master like the following:

```bash
 sudo salt 'proxydemo' foobar.proxy_echo baz
 proxydemo:
    baz...
    >>>baz
#and thank to the l33t if-else logic:
 sudo salt 'proxydemo' foobar.proxy_echo foo
 proxydemo:
    foo...
    >>>bar
```

Because the above code only contains the very basic code for a proxy minion only built-in grains data is availble. With `sudo salt 'proxydemo' grains.items` they may be inspected, but here is one of the more intersting built-in grains data:

```bash
$ sudo salt 'proxydemo' grains.item os
proxydemo:
    ----------
    os:
        proxy
```

A proper proxy minion would actually contact a device in its __init__() function, and return accordingly from initialized(). Then a ping() implementation also makes sense, and custom grains data could be requested from the proxied device and merged (as of 2016.11.3 and before *Nitrogen*) with `proxy_merge_grains_in_module: True` in `/etc/salt/proxy`. When the code actually does depend on some connection it usually does not make sense to allow the remote execution module to be called from the command line, so the docs rightfully suggest to limit `/srv/salt/_modules/foobar.py` in its __virtual__() function to return False if it is not called from a proxy module context.

