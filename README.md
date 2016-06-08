# helotism
Yet Another Raspberry Pi cluster

To install a minimal cluster with a minumum of hassle this project provides an installation routine for

- a central master server
- several nodes

The scope of this installation is to reduce the system administration aspects of networking, time synchronisation and storage.

![in scope of helotism](./business/marketing/images/helotism-scope.png)

The master server is also a node by default, but additionally provides

- a DHCP server
- a NTP server
- DNS resolution
- routing capabilities for the nodes

To connect to the outside world this board detects a USB ethernet adapter on one of the four USB ports. The installation cannot finish without such an adapter.

![USB to Ethernet Adapter](./technology/physical/raspberry-pi/rpi-3-b_udev_ID_PATH.png)

The locations 2-5 show where the USB to Ethernet Adapter is automatically recognized on the master node.

## Installation

See [-> Installation](./application/physical/installation.md "Installation")