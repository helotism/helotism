# helotism
Yet Another Raspberry Pi cluster

To install a minimal cluster with a minumum of hassle this project provides an installation routine for

- a central master server
- several nodes

These need to be connected with a switch and powered as usual.

It is recommended to add

- a RTC clock via I2C
- a button that triggers a shutdown of all connected nodes

The master server is also a node by default, but additionally provides

- a DHCP server
- a NTP server
- DNS resolution
- routing capabilities for the nodes

To connect to the outside world this board detects a USB ethernet adapter on one of the four USB ports. The installation cannot finish without such an adapter.

## Installation

The installation consists of writing to a number of SD cards and using these in Raspberry Pi 2 or 3 B.

Two scripts do all the work (including asking a minimum set of questions). Only the script boostrap-arch.sh needs to be run, it downloads the second script sdcardsetup.sh automatically.

By default the cluster spans its own netweork segment including an authoritative DHCP server for a dedicated subdomain. For all configuration items there are some default values set. They can be overridden during the configuration.

Only the bare necessities are prompted for during the installation. All additional system administration needs to be done either by hand, by using the bundled Saltstack installation or by installing an own config management.

There are two ways to start an installation:

- forking and cloning the repo
- just downloading the bootstrap script with curl

For a simple test with maybe 2 or 3 devices the bootstrap download is sufficient.

### The plain bootstrap script

Use it like

```bash
curl -o bootstrap-arch.sh http://FIXMEE.github.io/helotism/bootstrap-arch.sh
sudo sh bootstrap-arch.sh
```

It asks several questions and prints at the end how to restart the script with these parameters already preset.


### The forked repo method

For any cluster that should run for more than just simple evaluation tis method is recommended. The configuration management Saltstack connects to  a GitHub repo and an own fork gives not just the Helotism defaults but full customization capabilities.

Once forked and  cloned locally the bootstrap script can be run with the path

```bash
./application/physical/scripts/bootstrap-arch.sh
```
