---
title: Adding a USB ethernet adapter as second network device
layout: default
categories: [technology-physical_building-blocks]
abstract: The availability of the Raspberry Pi boards is ubiquitous and the community around them unparalleled in the world of small development boards. This counters some of the hardware shortcomings, such as the rather poor network connectivity.
---

# Adding a USB to ethernet adapter #

The availability of the Raspberry Pi boards is ubiquitous and the community around them unparalleled in the world of small development boards. This counters some of the hardware shortcomings, such as the rather poor network connectivity.

A major requirement of a cluster is to connect nodes not just with each other but also to a bigger network. An easy solution is to use a USB to ethernet adapter.

## The Belkin adapters ##

What I bought twice as "Belkin B2B048 USB 3.0 Gigabit Ethernet Adapter" were in fact two different products, the 2015 purchase has an ASIX chip and the 2016 a way smaller form factor and a Realtek chip.

Nevertheless both worked out of the box with 2015 Raspbians (still based in Debian Wheezy) as well as ArchLinuxARM installations. The quickest way to identify a device is with `lsusb`


```
$ lsusb
...
Bus 001 Device 005: ID 0b95:1790 ASIX Electronics Corp. AX88179 Gigabit Ethernet
...
```

```
$ lsusb
...
Bus 001 Device 012: ID 0bda:8153 Realtek Semiconductor Corp.
...
```

With the vendor and product ID more verbose output is returned (preferably called as root):

```
# lsusb -vd 0b95:1790
Bus 001 Device 005: ID 0b95:1790 ASIX Electronics Corp. AX88179 Gigabit Ethernet
Device Descriptor:
  bLength                18
  bDescriptorType         1
  bcdUSB               2.10
  bDeviceClass          255 Vendor Specific Class
  bDeviceSubClass       255 Vendor Specific Subclass
  bDeviceProtocol         0 
  bMaxPacketSize0        64
  idVendor           0x0b95 ASIX Electronics Corp.
  idProduct          0x1790 AX88179 Gigabit Ethernet
  bcdDevice            1.00
  iManufacturer           1 ASIX Elec. Corp.
  iProduct                2 AX88179
  iSerial                 3 000050B6152E37
...
    MaxPower              248mA
...
      iInterface              4 Network_Interface
...
```


A properly identified and usable network device also shows up in

```# ls /sys/class/net/
lan0  lo  uwan0  wlan1  wwan0
```

(Here after renaming the devices with systemd, but more about that later.)

```
# udevadm info /sys/class/net/uwan0
P: /devices/platform/soc/3f980000.usb/usb1/1-1/1-1.3/1-1.3:1.0/net/uwan0
E: DEVPATH=/devices/platform/soc/3f980000.usb/usb1/1-1/1-1.3/1-1.3:1.0/net/uwan0
E: ID_BUS=usb
E: ID_MODEL=AX88179
E: ID_MODEL_ENC=AX88179
E: ID_MODEL_FROM_DATABASE=AX88179 Gigabit Ethernet
E: ID_MODEL_ID=1790
E: ID_NET_LINK_FILE=/etc/systemd/network/70_rpi-3-b_usbport-bottom-middle.link
E: ID_NET_NAME=uwan0
E: ID_NET_NAME_MAC=enx0050b6152e37
E: ID_OUI_FROM_DATABASE=GOOD WAY IND. CO., LTD.
E: ID_PATH=platform-3f980000.usb-usb-0:1.3:1.0
E: ID_PATH_TAG=platform-3f980000_usb-usb-0_1_3_1_0
E: ID_REVISION=0100
E: ID_SERIAL=ASIX_Elec._Corp._AX88179_000050B6152E37
E: ID_SERIAL_SHORT=000050B6152E37
E: ID_TYPE=generic
E: ID_USB_CLASS_FROM_DATABASE=Vendor Specific Class
E: ID_USB_DRIVER=ax88179_178a
E: ID_USB_INTERFACES=:ffff00:
E: ID_USB_INTERFACE_NUM=00
E: ID_USB_SUBCLASS_FROM_DATABASE=Vendor Specific Subclass
E: ID_VENDOR=ASIX_Elec._Corp.
E: ID_VENDOR_ENC=ASIX\x20Elec.\x20Corp.
E: ID_VENDOR_FROM_DATABASE=ASIX Electronics Corp.
E: ID_VENDOR_ID=0b95
E: IFINDEX=3
E: INTERFACE=uwan0
E: SUBSYSTEM=net
E: SYSTEMD_ALIAS=/sys/subsystem/net/devices/uwan0 /sys/subsystem/net/devices/uwan0
E: TAGS=:systemd:
E: USEC_INITIALIZED=10770708
```


## The speedy network on a Raspberry Pi ##

Well, it only is twice as fast as the 100MBit ethernet, but still: The possibilities on the USB bus could be known better. And with those USB ethernet adapters working out of the box there is no reason not to have this tool in the box.


### The standard ethernet port ###

With an `sudo pacman -S iperf` on several nodes (or sudo salt '*' pkg.install iperf on a helotism installation  with SaltStack) "iPerf The TCP, UDP and SCTP network bandwidth measurement tool" https://iperf.fr/ is available (only dependencies are gcc-libs) and can be started on server mode on one node:

```
$ sudo iperf -s
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
[  4] local 10.166.15.115 port 5001 connected with 10.166.15.1 port 42882
[ ID] Interval       Transfer     Bandwidth
[  4]  0.0-10.0 sec   112 MBytes  94.2 Mbits/sec
```
(Later ended with Ctrl C.)

The other node then connects to the server by IP or hostname. Here the iPerf server was started on node spoke02, and some other node connects to it:

```
$ sudo iperf -c spoke02
------------------------------------------------------------
Client connecting to spoke02, TCP port 5001
TCP window size: 43.8 KByte (default)
------------------------------------------------------------
[  3] local 10.166.15.1 port 42882 connected with 10.166.15.115 port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec   112 MBytes  94.2 Mbits/sec
```

The **94.2 Mbits/sec** are the connection at the ethernet port.


### The USB adapter is twice as fast ###

The exact IP addresses are not important here, as this example connects to a Netgear WNDR3800 router running OpenWRT.

```
$ sudo iperf -s
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
[  4] local 10.116.16.1 port 5001 connected with 10.116.16.139 port 35578
[ ID] Interval       Transfer     Bandwidth
[  4]  0.0-10.0 sec   214 MBytes   178 Mbits/sec
^C$
```

```
$ sudo iperf -c 10.116.16.1
------------------------------------------------------------
Client connecting to 10.116.16.1, TCP port 5001
TCP window size: 43.8 KByte (default)
------------------------------------------------------------
[  3] local 10.116.16.139 port 35578 connected with 10.116.16.1 port 5001
[ ID] Interval       Transfer     Bandwidth
[  3]  0.0-10.0 sec   214 MBytes   179 Mbits/sec
```

The **179 Mbits/sec** are about twice the speed. Of course this does not perform magic and if there is a noce connected with such an adapter to the switch and another node functioning as the gateway with only the 100MBit-ethernet to said switch while with another USB ethernet adapter to the outside network: Then the bottleneck will remain at 100 MBit/sec no matter what.

But all these performance measurements are not the full picture as a second network adapter offers many more capabilities.

In this text the wording "USB Gigabit Ethernet Adapter" was carefully avoided as the USB 2.0 ports will not provide anthing near such speeds for the adapter.

## Configuring an USB ethernet adatper with systemd ##

To integrate these adapters into the network setup their location on the USB bus is of interest. A quick way to find their physical location is using `udevadm info` with the device path. Here lan0 is the renamed ethernet port of a Raspberry Pi 3 b:


```
# udevadm info /sys/class/net/lan0
P: /devices/platform/soc/3f980000.usb/usb1/1-1/1-1.1/1-1.1:1.0/net/lan0
E: DEVPATH=/devices/platform/soc/3f980000.usb/usb1/1-1/1-1.1/1-1.1:1.0/net/lan0
E: ID_BUS=usb
E: ID_MODEL=ec00
E: ID_MODEL_ENC=ec00
E: ID_MODEL_FROM_DATABASE=SMSC9512/9514 Fast Ethernet Adapter
E: ID_MODEL_ID=ec00
E: ID_NET_DRIVER=smsc95xx
E: ID_NET_LINK_FILE=/etc/systemd/network/20_rpi-3-b_ethernetport.link
E: ID_NET_NAME=lan0
E: ID_NET_NAME_MAC=enxb827eb8fb86b
E: ID_OUI_FROM_DATABASE=Raspberry Pi Foundation
E: ID_PATH=platform-3f980000.usb-usb-0:1.1:1.0
E: ID_PATH_TAG=platform-3f980000_usb-usb-0_1_1_1_0
E: ID_REVISION=0200
E: ID_SERIAL=0424_ec00
E: ID_TYPE=generic
E: ID_USB_CLASS_FROM_DATABASE=Vendor Specific Class
E: ID_USB_DRIVER=smsc95xx
E: ID_USB_INTERFACES=:ff00ff:
E: ID_USB_INTERFACE_NUM=00
E: ID_VENDOR=0424
E: ID_VENDOR_ENC=0424
E: ID_VENDOR_FROM_DATABASE=Standard Microsystems Corp.
E: ID_VENDOR_ID=0424
E: IFINDEX=2
E: INTERFACE=lan0
E: SUBSYSTEM=net
E: SYSTEMD_ALIAS=/sys/subsystem/net/devices/lan0 /sys/subsystem/net/devices/lan0
E: TAGS=:systemd:
E: USEC_INITIALIZED=13051220
```

The DEVPATH and ID_PATH variables give the physical location which can be used later in a convenient way with systemd.

Repeating this udevadm call with USB ethernet adapters on several USB ports reveals this layout:

![The installation workflow]({{ "/technology/physical/raspberry-pi/rpi-3-b_udev_ID_PATH.svg" | prepend: site.baseurl }})

Here is the DEVPATH on the lower left USB port:

```
# udevadm info /sys/class/net/lan0 | grep ID_PATH
E: ID_PATH=platform-3f980000.usb-usb-0:1.3:1.0

```

So the physical location varies like

- ID_PATH=platform-3f980000.usb-usb-0:1.**1**:1.0
- ID_PATH=platform-3f980000.usb-usb-0:1.**3**:1.0


### The structure of systemd network device configuration ###

There are

- device configuration *"foobar.**link**"* ([man page](https://www.freedesktop.org/software/systemd/man/systemd.link.html)) and

- network configuration *"foobar.**network**"* ([man page](https://www.freedesktop.org/software/systemd/man/systemd.network.html)) files

with the device configuration being called by a udev component. As usual with systemd, their location bay be in three different places, namely */usr/lib/systemd/network*, */run/systemd/network* or */etc/systemd/network* with files in */etc* having the highest priority.

#### The .link device configuration

This files contains the two sections **[Match]** and **[Link]** and it is the [Match] section where the USB bus location comes in handy: It pays to read all systemd documentation carefully for the the word "glob":

>[Match] Section Options
>
>Path=
>A whitespace-separated list of shell-style **globs** matching the persistent path, as exposed by the udev property "ID_PATH".

Globbing means more than just the widcard with asterisks, but also character lists in square brackets, [amongst other things](http://www.tldp.org/LDP/abs/html/globbingref.html).

So a `Path=platform-3f980000.usb-usb-0:1.[245]:1.0` does match the three ports besides the lower left one.

Which makes it trivially easy to not just rename the device (a HUGE discussion when systemd first hit the distros) but als set the maximum MTU or configure WOL wake on lan.

Even a random MAC address can easily be achieved, something can might come handy when testing an initial setup and forcing a DHCP server to hand out a new IP address every time:

```
# cat /etc/systemd/network/70_rpi-3-b_usbports.link 
[Match]
Path=platform-3f980000.usb-usb-0:1.**[245]**:1.0

[Link]
MACAddressPolicy=random
NamePolicy=mac
```

On the other hand a fixed device name like seen above is configured with:

```
# cat /etc/systemd/network/70_rpi-3-b_usbport-bottom-middle.link 
[Match]
Path=platform-3f980000.usb-usb-0:1.3:1.0

[Link]
Name=uwan0
```

The above means that on the lower left USB port a USB ethernet adapter will always be given the device name uwan0 (which might stand for USB WAN area device 0, but can be freely chosen).

Of course the udev-way of writing into udev rule files is also possible. But there is a certain elegance in this and its sibling config file to complete a network configuration:

#### The network configuration

With such a fixed device name a basic network configuration looks like this:

```
# cat /etc/systemd/network/70_rpi-3-b_usbport-bottom-middle.network 
[Match]
Name=uwan0

[Network]
DHCP=ipv4
```
As uwan0 will only be applied to devices in that lower left USB port this is a rock-solid setup to link the Helotism cluster to an uplink router and get a dynamic IP address.

The [man page](https://www.freedesktop.org/software/systemd/man/systemd.link.html) list several example configurations at the end of the page.

A lightweight DHCP server is available, although not used in the Helotism project as Dnsmasq offers additional features.

One of the basic requirements of the Helotism project is to provide several network-related capabilities:

![The installation workflow]({{ "/business/marketing/images/helotism-scope.svg" | prepend: site.baseurl }})

The **router** capability is very easily achieved with this setting in one of the `.network` files:

```
# cat /etc/systemd/network/20_rpi-3-b_ethernetport.router.network 
[Match]
Name=lan0
  
[Network]
Address=10.166.15.1/24
IPForward=ipv4
IPMasquerade=yes
```

The options `IPForward` and `IPMasquerade` are all that is needed to turn that board into a router:

- `IPForward` does set the sysctl setting ip_forward

```
# sysctl -a | grep ip_forward
net.ipv4.ip_forward = 1

```

- `IPMasquerade` does set an iptables rule in the nat chain for POSTROUTING:


```
# iptables -t nat -L POSTROUTING
Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  10.166.15.0/24       anywhere
```

The behaviour might change in the future from iptables to nftables: [[systemd-devel] [HEADSUP] nspawn/networkd: moving from iptables to	nftables](https://lists.freedesktop.org/archives/systemd-devel/2015-May/032531.html), so following the [change log ](https://github.com/systemd/systemd/blob/master/NEWS) is always a good idea.

As visible above the setting is to enable masquerading **on all devices**. If this behaviour is not desired, of course iptables can be configured as usual (minus the settings in the .network files).

Overall a very convenient configuration.

## A minimal example ##

An USB ethernet adapter plugged into a current ArchLinuxARM installation is automatically detected, without the need for a `.link` configuration file. Here the output of a 2016 version of the "Belkin B2B048 USB 3.0 Gigabit Ethernet Adapter":

```
# lsusb
Bus 001 Device 003: ID 0424:ec00 Standard Microsystems Corp. SMSC9512/9514 Fast Ethernet Adapter
...

# lsusb -vd 0bda:8153

Bus 001 Device 004: ID 0bda:8153 Realtek Semiconductor Corp. 
Device Descriptor:
  bLength                18
  bDescriptorType         1
  bcdUSB               2.10
  bDeviceClass            0 
  bDeviceSubClass         0 
  bDeviceProtocol         0 
  bMaxPacketSize0        64
  idVendor           0x0bda Realtek Semiconductor Corp.
  idProduct          0x8153 
  bcdDevice           30.00
  iManufacturer           1 Realtek
  iProduct                2 USB 10/100/1000 LAN
...
```

Without any renaming done on udev level the preditive device name is:

```
# ls /sys/class/net/
**enxa0cec81ebdda**  lan0  lo
```

The bad news is: This name `enxa0cec81ebdda` is the same for all four USB ports! So for any etwork devices of importance it may be better to standardize the name with a `.link` configuration file.

But as a minimal example for a second network device on a Raspberry Pi the following configuration gives full control over a second IP address:

```
[Match]
Name=en*

[Network]
DHCP=ipv4
```

Or for a static address:

```
[Match]
Name=en*

[Network]
Address=192.168.0.15/24
Gateway=192.168.0.1
```


