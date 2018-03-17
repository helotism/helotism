#!/usr/bin/env bash
#/** 
#  * This script automates the installation instructions at
#  * https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3
#  *
#  * Used with parameter -d like e.g. sudo ./application/physical/sdcardsetup-helotism.sh -b /dev/mmcblk0
#  */


#set -o nounset #exit on undeclared variable
# bootstrap runtime
__BLOCKDEVICE=''                  #b
__BLOCKDEVICESIZE=0               #if ~8GB and bigger, then only use ~5GB. The idea is to reserve space for a "data" partition.
__ROOTPARTITIONSIZE=''            #
_VERBOSE='false'                  #@TODO: Use it
_PLATFORM="rpi-2"                 #@TODO: rename
__HOSTNAME=''                     #n important parameter
VERSION=1                         #@TODO: Use it
# The remote repository          
__GITREMOTEORIGINURL=''           #r
__GITREMOTEORIGINBRANCH=''        #g
# About the cluster              
__COUNT=''                        #c
__MASTERHOSTNAME=''               #m
__HOSTNAMEPREFIX=''               #n
__ADMINUSERNAME='helotism'
__ADMINUSERENCRYPTEDPASSWORD='$6$b9JBVFWB.uYu6ROo$JXgK5n5srdULqNzPAzIXTH3qRyBJU6te.wXNMn3EK.lbFd5CBAkUajf9adczRUtZc.2Sf5eTW2TvpkMVPVCvt/'
# Network settings               
__NETWORKSEGMENTCIDR=''           #s
__MASTERIP=''                     #
__NETWORKPREFIX=''                #
__NETWORKSEGMENT='255.255.255.0'  #
__DHCPRANGESTARTIP=''             #a
__DHCPRANGEENDIP=''               #o
__FQDNNAME=''                     #d



#http://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
_SUDO=''
if (( $EUID != 0 )); then
  while true; do sudo ls; break; done
  _SUDO='sudo'
fi; #from now on this is possible: $SUDO some_command

#check if directories exist
for d in 'data/incoming/archlinuxarm' 'tmp'; do
  if [ ! -d $d ]; then mkdir -p $d; fi
done

#@TODO: Maybe use environment variables?
while getopts ":hvpb:n:m:d:r:g:i:s:a:o:c:" opt; do
  case $opt in
    a) __DHCPRANGESTARTIP=$OPTARG
    ;;
    b) __BLOCKDEVICE=$OPTARG
    ;;
    c) __COUNT=$OPTARG
    ;;
    d) __FQDNNAME=$OPTARG
    ;;
    e) echo "The parameter -e for the __ADMINUSERENCRYPTEDPASSWORD is not implemented yet;" #__ADMINUSERENCRYPTEDPASSWORD=$OPTARG
    ;;
    g) __GITREMOTEORIGINBRANCH=$OPTARG
    ;;
    h) echo "help!"
    ;;
    i) __MASTERIP=$OPTARG
    ;;
    m) __MASTERHOSTNAME=$OPTARG
    ;;
    n) __HOSTNAME=$OPTARG
    ;;
    o) __DHCPRANGEENDIP=$OPTARG
    ;;
    p) echo "Only rpi-2 implemented yet. As of 2016-05 this is the official ArchLinuxARM way for rpi-3." #_PLATFORM=$OPTARG
    ;;
    r) __GITREMOTEORIGINURL=$OPTARG
    ;;
    s) __NETWORKSEGMENTCIDR=$OPTARG; __NETWORKPREFIX="${__NETWORKSEGMENTCIDR%.*}.0"; __NETWORKSEGMENT='255.255.255.0'
    ;;
    u) echo "The parameter -u for the __ADMINUSERNAME is not implemented yet;" #__ADMINUSERNAME=$OPTARG
    ;;
    v) _VERBOSE="true"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; echo -n "continuing "; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo ".";
    ;;
  esac;
done  #end while getopts


#https://stackoverflow.com/a/37939589
version() {
  echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }';
}

#Trying to keep this to a minimum.
#Script tested and developed on Ubuntu 16.04
checkrequirements() {
  i=0;
  type awk >/dev/null 2>&1 || { echo >&2 "This script requires awk but it is not installed. ";  i=$((i + 1)); }
  type wget >/dev/null 2>&1 || { echo >&2 "This script requires wget but it is not installed. ";  i=$((i + 1)); }
  type fdisk >/dev/null 2>&1 || { echo >&2 "This script requires fdisk but it is not installed. ";  i=$((i + 1)); }
  type curl >/dev/null 2>&1 || { echo >&2 "This script requires curl but it is not installed. ";  i=$((i + 1)); }
  type bsdtar >/dev/null 2>&1 || { echo >&2 "This script requires bsdtar but it is not installed. ";  i=$((i + 1)); }
  type dd >/dev/null 2>&1 || { echo >&2 "This script requires dd but it is not installed. ";  i=$((i + 1)); }
  type git >/dev/null 2>&1 || { echo >&2 "This script requires git but it is not installed. ";  i=$((i + 1)); }
  type lsblk >/dev/null 2>&1 || { echo >&2 "This script requires lsblk but it is not installed. ";  i=$((i + 1)); }

  BSDTARVERSION=$(bsdtar --version | cut -d" " -f2)
  if [ $(version $BSDTARVERSION) -lt $(version "3.3.0") ]; then
    echo >&2 "This script requires bsdtar version 3.3+ or higher but it is not installed. See https://github.com/helotism/helotism/issues/8";  i=$((i + 1));
  fi

  if [[ $i > 0 ]]; then echo "Aborting."; echo "Please install the missing dependency."; exit 1; fi
} #end function checkrequirements


######################################################################
#/**
#  * Main part
#  *
#  */

clear
checkrequirements

#was the parameter supplied?
if [ -z $__BLOCKDEVICE ]; then
  echo "You must specify a block device to be overwritten!"
  exit;
else
  $_SUDO umount -f ${__BLOCKDEVICE}p{1,2,3,4,5} 2> /dev/null #for good measure
fi;

clear
echo -e "\nThis script wants to overwrite the block device ${__BLOCKDEVICE} with ArchLinuxARM-${_PLATFORM}-latest."
while true; do
  read -p "Overwrite ${__BLOCKDEVICE}? [yN] " yn
  [ -z "$yn" ] && yn=n
  case $yn in
    [Yy]* ) 
      if [ ! -b ${__BLOCKDEVICE} ]; then echo "The block device ${__BLOCKDEVICE} does not exist.";
        echo "Exiting.";
        exit 1;
      else #there is a block device
        if grep -qs "${__BLOCKDEVICE}p" /proc/mounts ;
          then $_SUDO umount -f ${__BLOCKDEVICE}p{1,2,3,4,5} 2> /dev/null ; echo "Unmounted partitions.";
        fi

        if [ -f /sys/class/block/${__BLOCKDEVICE##*/}/size ]; then
          __BLOCKDEVICESIZE=$(cat /sys/class/block/${__BLOCKDEVICE##*/}/size)
        fi

      fi
      break;;
    [Nn]* ) echo "Sure. Aborting."; exit;;
    * ) echo "Please answer yes or no";;
  esac
done


#/**
#  * Downloading the latest ArchLinuxARM installation file.
#  *
#  * The nice thing is that it is a tarred filesystem, and not an image.
#  * This makes it really easy to make changes to the filesystem.
#  *
#  */

sleep 2; clear
echo ""
if [ ! -f ./data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz ]; then
  while true; do
    read -p "Downloading potentially large file ${_PLATFORM}? [Yn] " yn
    #[ -z "$yn" ] && [ "$yn$ = "y" ]
    case $yn in
      [Yy]* ) wget "$_Q" --limit-rate=1000k http://archlinuxarm.org/os/ArchLinuxARM-${_PLATFORM}-latest.tar.gz -c -O data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz;
              break;;
      [Nn]* ) echo "Maybe run later wget --limit-rate=1000k http://archlinuxarm.org/os/ArchLinuxARM-${_PLATFORM}-latest.tar.gz -c -O data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz ?";
              echo "Aborting.";
              exit;;
      * )     echo "Please answer yes or no";;
    esac
  done
else
  echo "File ArchLinuxARM-${_PLATFORM}-latest.tar.gz existing, checking for updates."
  if [[ "$_SUDO $(curl --limit-rate 1000k http://archlinuxarm.org/os/ArchLinuxARM-${_PLATFORM}-latest.tar.gz -z data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz -o data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz --silent --location --write-out %{http_code};)" == "200" ]]; then
    echo "The file data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz was updated.";
  else
    echo "The file data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz was already up-to-date."
  fi;
fi;

#/**
#  * Making permanent changes to the block device.
#  *
#  */

sleep 2; clear
echo ""
$_SUDO dd if=/dev/zero of=${__BLOCKDEVICE} bs=1M count=8 status=none;

if [ ${__BLOCKDEVICESIZE} -gt 7000000 ]; then #8GB and more
  __ROOTPARTITIONSIZE='+5G'
else
  __ROOTPARTITIONSIZE=$(( ${__BLOCKDEVICESIZE} - 1 ));
fi

#http://superuser.com/questions/332252/creating-and-formating-a-partition-using-a-bash-script
echo "Creating partition table on ${__BLOCKDEVICE}."; sleep 3; #last chance saloon
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | $_SUDO fdisk $__BLOCKDEVICE > /dev/null
  o #delete old partitions
  n #
  p #
  1 #

  +200M #
  t #
  c #to set the first partition to type W95 FAT32 (LBA).
  n #
  p #
  2 #
  
  ${__ROOTPARTITIONSIZE} #
  w #Write the partition table and exit
EOF

$_SUDO  fdisk -l ${__BLOCKDEVICE}
sleep 6

echo "Creating filesystems."
#filesystem boot partition
$_SUDO mkfs.vfat "${__BLOCKDEVICE}1" > /dev/null
if [ ! -d ./tmp/boot ]; then mkdir ./tmp/boot; fi
$_SUDO mount "${__BLOCKDEVICE}1" ./tmp/boot

#filesystem main partition
$_SUDO mkfs.ext4 -q -F "${__BLOCKDEVICE}2"  > /dev/null #-F -F will even take mounted partitions.
if [ ! -d ./tmp/root ]; then mkdir ./tmp/root; fi
$_SUDO mount "${__BLOCKDEVICE}2" ./tmp/root

echo "Copying to device ${__BLOCKDEVICE}."
if [ $_VERBOSE == "true" ]; then
  pv data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz | $_SUDO bsdtar -xpf - -C ./tmp/root
else
  $_SUDO bsdtar -xpf data/incoming/archlinuxarm/ArchLinuxARM-${_PLATFORM}-latest.tar.gz -C ./tmp/root
fi;

echo -n "Setting up boot partition."
$_SUDO mv ./tmp/root/boot/* ./tmp/boot
echo "."

######################################################################
#/**
#  * Configuration customization.
#  * Making changes to the staged filesystem.
#  * master and non-master
#  *
#  * When writing a file from scratch the sed removes the fixed intendation string "leading whitespace followed by <trim />
#  * When the script is stabilized this will change to <<- operator trimming only tabs.
#  * But at the moment because of lots of copy&paste from a shell and such I prefer this way.
#  *
#  */

sleep 1; clear

tmp=''
if [ ! -z "$__HOSTNAME"  ]; then
  tmp=${__HOSTNAME}; if [ ! -z "$__FQDNNAME" ]; then tmp+=".$__FQDNNAME"; fi
  echo "Setting hostname to ${tmp}.";
  echo ${tmp} > ./tmp/root_etc_hostname ;
  $_SUDO mv ./tmp/root_etc_hostname ./tmp/root/etc/hostname ;
fi

if [ ! -d ./tmp/root/etc/systemd/network ]; then mkdir -p ./tmp/root/etc/systemd/network ; fi

#the network for an USB ethernet adapter
if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.link ]; then #not in a cloned/forked repo
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.link > /dev/null
    <trim />[Match]
    <trim />Path=platform-3f980000.usb-usb-0:1.[2345]:1.0
    <trim />
    <trim />[Link]
    <trim />#MACAddressPolicy=random
    <trim />#NamePolicy=mac
    <trim />Name=usbwan0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.link ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.link
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.link ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.link
fi

if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.network ]; then #not in a cloned/forked repo
sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.network > /dev/null
  <trim />[Match]
  <trim />Name=usbwan0
  <trim />Path=platform-3f980000.usb-usb-0:1.[2345]:1.0
  <trim />
  <trim />[Network]
  <trim />DHCP=ipv4
  <trim />IPv6AcceptRouterAdvertisements=0
  <trim />
  <trim />[Address]
  <trim />Label=usbwan0:0
  <trim />Address=${__MASTERHOSTNAME%.*}.2
  <trim />
  <trim />#use this to set your own alias IP
  <trim />#[Address]
  <trim />#Label=usbwan0:1
  <trim />#Address=aaa.bbb.ccc.ddd
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.network ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.network
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports.network ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports.network
fi

#the network for an EDIMAX WiFi dongle
if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/50_rpi-3-b_usbports-edimax.link ]; then #not in a cloned/forked repo
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/50_rpi-3-b_usbports-edimax.link > /dev/null
    <trim />[Match]
    <trim />Path=platform-3f980000.usb-usb-0:1.[2345]:1.0
    <trim />Driver=rtl8192cu
    <trim />
    <trim />[Link]
    <trim />Name=wifiwan0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/50_rpi-3-b_usbports-edimax.link ./application/physical/systemd/assets/etc/systemd/network/50_rpi-3-b_usbports-edimax.link
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/50_rpi-3-b_usbports-edimax.link ./tmp/root/etc/systemd/network/50_rpi-3-b_usbports-edimax.link
fi

if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/50_rpi-3-b_usbports-edimax.network ]; then #not in a cloned/forked repo
sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/50_rpi-3-b_usbports-edimax.network > /dev/null
  <trim />[Match]
  <trim />Name=wifiwan0
  <trim />Path=platform-3f980000.usb-usb-0:1.[2345]:1.0
  <trim />
  <trim />[Network]
  <trim />DHCP=ipv4
  <trim />IPv6AcceptRouterAdvertisements=0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/50_rpi-3-b_usbports-edimax.network ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports-edimax.network
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/70_rpi-3-b_usbports-edimax.network ./tmp/root/etc/systemd/network/70_rpi-3-b_usbports-edimax.network
fi

#the network on the ethernet port
if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.link ]; then #not in a cloned/forked repo
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.link > /dev/null
    <trim />[Match]
    <trim />Path=platform-3f980000.usb-usb-0:1.1:1.0
    <trim />
    <trim />[Link]
    <trim />Name=lan0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.link ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.link
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.link ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.link
fi

#better only set this if the parameter was supplied
if [ ! -z "$__MASTERHOSTNAME" ]; then

  echo "Setting salt master to ${__MASTERHOSTNAME}.";
  if [ ! -d ./tmp/root/etc/salt/minion.d ]; then mkdir -p ./tmp/root/etc/salt/minion.d; fi
  echo "master: ${__MASTERHOSTNAME}" > ./tmp/root/etc/salt/minion.d/99-master-address.conf #repeated in following salt-bootstrap instructions

  #Hopefully this does not break anything later on: Manipulating the hosts file
  tmp=''
  if [ ! -z "${__MASTERIP}" ]; then tmp+="${__MASTERIP}"; fi
  if [ ! -z "${__MASTERHOSTNAME}" -a ! -z "${__FQDNNAME}" ]; then tmp+=" ${__MASTERHOSTNAME}.${__FQDNNAME}"; fi
  if [ ! -z "${__MASTERHOSTNAME}" ]; then tmp+=" ${__MASTERHOSTNAME}"; fi
  if [ ! -z "$tmp" ]; then $_SUDO echo "${tmp}" >> ./tmp/root/etc/hosts; fi
fi

######################################################################
#/**
#  * Configuration customization.
#  * Making changes to the staged filesystem.
#  * master
#  *
#  */
if [ "$__HOSTNAME" = "$__MASTERHOSTNAME" ]; then

  for d in etc/salt/minion.d etc/salt/master.d srv/salt srv/pillar srv/pillar/users srv/pillar/network; do
    if [ ! -d ./tmp/root/${d} ]; then $_SUDO mkdir -p ./tmp/root/${d}; fi
    if [ ! -d ./application/physical/saltstack/assets/${d} ]; then mkdir -p ./application/physical/saltstack/assets/${d}; fi
  done

  #TODO: Change sudoers logic to only grant ALL rights when an individual password is supplied
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/pillar/users/admin.sls > /dev/null
    <trim />users:
    <trim />  helotism:
    <trim />    fullname: Helotism Project Admin User
    <trim />    password: $6$T.6rE1VzbTO4mnu7$3TXuy4rpTPMB0TD38BuAyaEmaPnJN67o/QVFE0zX0hl1HU4vOC2Ib9r3iwSMdzlXQMINlwhJNwDx28s9ERjQA.
    <trim />    enforce_password: True
    <trim />    sudouser: True
    <trim />    sudo_rules:
    <trim />      - ALL=(ALL) NOPASSWD:ALL
EOF

  #master saltstack salt-master ext_pillar
  if [ ! -f ./application/physical/saltstack/assets/etc/salt/master.d/90_ext_pillar.conf ]; then
    if [ ! -z ${__GITREMOTEORIGINURL} ]; then #repeated for clarity/safety/...
      sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/salt/master.d/90_ext_pillar.conf > /dev/null
        <trim />ext_pillar:
        <trim />  - git:
        <trim />    - ${__GITREMOTEORIGINBRANCH} ${__GITREMOTEORIGINURL}:
        <trim />      - root: application/physical/saltstack/assets/srv/pillar
EOF
      $_SUDO cp ./tmp/root/etc/salt/master.d/90_ext_pillar.conf ./application/physical/saltstack/assets/etc/salt/master.d/90_ext_pillar.conf
    fi
  else
    $_SUDO cp ./application/physical/saltstack/assets/etc/salt/master.d/90_ext_pillar.conf ./tmp/root/etc/salt/master.d/90_ext_pillar.conf
  fi

  #master saltstack salt-master gitfs_remotes
  if [ ! -f ./application/physical/saltstack/assets/etc/salt/master.d/90_gitfs_remotes.conf ]; then
    if [ ! -z ${__GITREMOTEORIGINURL} ]; then #repeated for clarity/safety/...
      sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/salt/master.d/90_gitfs_remotes.conf > /dev/null
        <trim />gitfs_remotes:
        <trim />  - ${__GITREMOTEORIGINURL}:
        <trim />    - root: application/physical/saltstack/assets/srv/salt
        <trim />    - base: ${__GITREMOTEORIGINBRANCH}
        <trim />  - ${__GITREMOTEORIGINURL}:
        <trim />    - name: dnsmasq_formula
        <trim />    - root: application/physical/saltstack/vendor/saltstack-formulas/dnsmasq_formula
        <trim />    - base: ${__GITREMOTEORIGINBRANCH}
        <trim />  - ${__GITREMOTEORIGINURL}:
        <trim />    - name: ntp_formula
        <trim />    - root: application/physical/saltstack/vendor/saltstack-formulas/ntp_formula
        <trim />    - base: ${__GITREMOTEORIGINBRANCH}
        <trim />  - ${__GITREMOTEORIGINURL}:
        <trim />    - name: users_formula
        <trim />    - root: application/physical/saltstack/vendor/saltstack-formulas/users_formula
        <trim />    - base: ${__GITREMOTEORIGINBRANCH}
EOF
    $_SUDO cp ./tmp/root/etc/salt/master.d/90_gitfs_remotes.conf ./application/physical/saltstack/assets/etc/salt/master.d/90_gitfs_remotes.conf
    fi
  else
    $_SUDO cp ./application/physical/saltstack/assets/etc/salt/master.d/90_gitfs_remotes.conf ./tmp/root/etc/salt/master.d/90_gitfs_remotes.conf
  fi

  #master saltstack salt-master fileserver_backends
  if [ ! -f ./application/physical/saltstack/assets/etc/salt/master.d/90_fileserver_backend.conf ]; then
    sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/salt/master.d/90_fileserver_backend.conf > /dev/null
      <trim />fileserver_backend:
      <trim />  - roots
      <trim />  - git
EOF
    $_SUDO cp ./tmp/root/etc/salt/master.d/90_fileserver_backend.conf ./application/physical/saltstack/assets/etc/salt/master.d/90_fileserver_backend.conf
  else
    $_SUDO cp ./application/physical/saltstack/assets/etc/salt/master.d/90_fileserver_backend.conf ./tmp/root/etc/salt/master.d/90_fileserver_backend.conf
  fi

  #master saltstack minions grains
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/salt/minion.d/grains.conf > /dev/null
    <trim />grains:
    <trim />  roles:
    <trim />    - dhcp-server
    <trim />#    - salt-master
    <trim />#   - i2c-rtc
    <trim />#    - dns-server
    <trim />    - ntp-server
    <trim />#    - proxy-cache
    <trim />#    - network-router
    <trim />    - power-button
EOF

  #master saltstack pillar
  #I /believe/ that the pillar system is more fragile so I do not change the
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/pillar/top.sls > /dev/null
    <trim />base:
    <trim />  '*':
    <trim />    - helotism
    <trim />
    <trim />  'roles:dhcp-server':
    <trim />    - match: grain
    <trim />    - dhcp-server
    <trim />
    <trim />  'roles:ntp-server':
    <trim />    - match: grain
    <trim />    - ntp-server
EOF

  #master saltstack salt ntp-server
  #nodes get the NTP server via DHCP option
  if [ ! -f ./application/physical/saltstack/assets/srv/salt/ntp-server.sls ]; then
    sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/salt/ntp-server.sls > /dev/null
      <trim />include:
      <trim />  - ntp/ng
EOF
    $_SUDO cp ./tmp/root/srv/salt/ntp-server.sls ./application/physical/saltstack/assets/srv/salt/ntp-server.sls
  else
    $_SUDO cp ./application/physical/saltstack/assets/srv/salt/ntp-server.sls ./tmp/root/srv/salt/ntp-server.sls
  fi

  if [ ! -f ./application/physical/systemd/assets/etc/systemd/timesyncd.conf ]; then #not in a cloned/forked repo
    sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/timesyncd.conf > /dev/null
      <trim />[Time]
      <trim />NTP=${__MASTERIP}
      <trim />FallbackNTP=0.arch.pool.ntp.org 1.arch.pool.ntp.org 2.arch.pool.ntp.org 3.arch.pool.ntp.org
EOF
    $_SUDO cp ./tmp/root/etc/systemd/timesyncd.conf ./application/physical/systemd/assets/etc/systemd/timesyncd.conf
  else
    $_SUDO cp ./application/physical/systemd/assets/etc/systemd/timesyncd.conf ./tmp/root/etc/systemd/timesyncd.conf
  fi


  #master saltstack pillar ntp-server
  #TODO: Test reliance on helotism file
  #FIXME: Breaks on nonexisting file /srv/pillar/helotism.sls
  if [ ! -f ./application/physical/saltstack/assets/srv/pillar/ntp-server.sls ]; then
    sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/pillar/ntp-server.sls > /dev/null
      <trim />{% from 'helotism.sls' import vars %}
      <trim />ntp:
      <trim />  ng:
      <trim />    settings:
      <trim />      ntpd: True
      <trim />      ntp_conf:
      <trim />        server: ['127.127.1.1', '0.de.pool.ntp.org', '1.de.pool.ntp.org', '2.de.pool.ntp.org', '3.de.pool.ntp.org']
      <trim />        fudge: ['127.127.1.1 stratum 12']
      <trim />        interface: ['listen lan0', 'listen lo' ]
      <trim />        driftfile: ['/var/lib/ntp/ntp.drift']
      <trim />{% if vars.helotism.__NETWORKSEGMENT is defined and vars.helotism.__NETWORKPREFIX is defined %}
      <trim />        restrict: ['default nomodify nopeer noquery', '127.0.0.1', '::1', '{{ vars.helotism.__NETWORKPREFIX }} mask {{ vars.helotism.__NETWORKSEGMENT }} nomodify nopeer notrap']
      <trim />{% else %}
      <trim />        restrict: ['default nomodify nopeer noquery', '127.0.0.1', '::1', '${__NETWORKPREFIX} mask ${__NETWORKSEGMENT} nomodify  nopeer notrap']
      <trim />{% endif %}
EOF
    $_SUDO cp ./tmp/root/srv/pillar/ntp-server.sls ./application/physical/saltstack/assets/srv/pillar/ntp-server.sls
  else
     $_SUDO cp ./application/physical/saltstack/assets/srv/pillar/ntp-server.sls ./tmp/root/srv/pillar/ntp-server.sls
  fi


  #master saltstack pillar dhcp-server dns-server
  if [ ! -f ./application/physical/saltstack/assets/srv/pillar/dhcp-server.sls ]; then
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/pillar/dhcp-server.sls > /dev/null
    <trim />dnsmasq:
    <trim />  dnsmasq_conf: salt://dnsmasq/files/dnsmasq.conf
    <trim />  dnsmasq_hosts: salt://dnsmasq/files/dnsmasq.hosts
    <trim />  dnsmasq_cnames: salt://dnsmasq/files/dnsmasq.cnames
    <trim />  dnsmasq_conf_dir: salt://dnsmasq/files/dnsmasq.d
    <trim />
    <trim />  settings:
    <trim />    port: 53
    <trim />
    <trim />    interface:
    <trim />      - lan0
    <trim />      - lo
    <trim />    listen-address:
    <trim />      - 127.0.0.1
    <trim />      - ${__MASTERIP}
    <trim />
    <trim />    domain-needed: True
    <trim />    bogus-priv: True
    <trim />    expand-hosts: True
    <trim />    domain: ${__FQDNNAME}
    <trim />
    <trim />    dhcp-authoritative: True
    <trim />    dhcp-range:
    <trim />      - ${__DHCPRANGESTARTIP},${__DHCPRANGEENDIP},12h
    <trim />
    <trim />    dhcp-option:
    <trim />      - 3, 0.0.0.0
    <trim />      - option:router, 0.0.0.0
    <trim />      - 42, ${__MASTERIP}
    <trim />      - option:ntp-server, ${__MASTERIP}
    <trim />
    <trim />    auth-zone:
    <trim />      - ${__FQDNNAME},${__NETWORKSEGMENTCIDR}
EOF
    $_SUDO cp ./tmp/root/srv/pillar/dhcp-server.sls ./application/physical/saltstack/assets/srv/pillar/dhcp-server.sls
  else
     $_SUDO cp ./application/physical/saltstack/assets/srv/pillar/dhcp-server.sls ./tmp/root/srv/pillar/dhcp-server.sls
  fi

  #master saltstack salt
  #$_SUDO tee ./tmp/root/srv/salt/top.sls > /dev/null <<EOF
  if [ ! -f ./application/physical/saltstack/assets/srv/salt/top.sls ]; then
    sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/srv/salt/top.sls > /dev/null
      <trim />base:
      <trim />  '*':
      <trim />    - helotism
      <trim />    - common
      <trim />
      <trim />  'roles:dhcp-server':
      <trim />    - match: grain
      <trim />    - dhcp-server
      <trim />
      <trim />  'roles:ntp-server':
      <trim />    - match: grain
      <trim />    - ntp-server
      <trim />
      <trim />  'roles:power-button':
      <trim />    - match: grain
      <trim />    - power-button
EOF
    $_SUDO cp ./tmp/root/srv/salt/top.sls ./application/physical/saltstack/assets/srv/salt/top.sls
  else
     $_SUDO cp ./application/physical/saltstack/assets/srv/salt/top.sls ./tmp/root/srv/salt/top.sls
  fi

  if [ -f ./tmp/srv_pillar_helotism.sls ]; then $_SUDO cp ./tmp/srv_pillar_helotism.sls ./tmp/root/srv/pillar/helotism.sls ; fi

if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.router.network ]; then #not in a cloned/forked repo
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.router.network > /dev/null
      <trim />[Match]
      <trim />Name=lan0
  
      <trim />[Network]
      <trim />Address=${__NETWORKSEGMENTCIDR}
      <trim />IPForward=ipv4
      <trim />IPMasquerade=yes
      <trim />IPv6AcceptRouterAdvertisements=0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.router.network ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.router.network
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.router.network ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.router.network
fi

  #master systemd resolved
if [ ! -f ./application/physical/systemd/assets/etc/systemd/resolved.conf ]; then
  sed 's/^[ ]*<trim \/>//' <<EOF | $_SUDO tee ./tmp/root/etc/systemd/resolved.conf > /dev/null
    <trim />[Resolve]
    <trim />DNS=${__MASTERIP}
    <trim />Domains=${__FQDNNAME}
    <trim />#closes port 5355 for Link-local Multicast Name Resolution
    <trim />LLMNR=0
EOF
  $_SUDO cp ./tmp/root/etc/systemd/resolved.conf ./application/physical/systemd/assets/etc/systemd/resolved.conf
else
  $_SUDO cp ./application/physical/systemd/assets/etc/systemd/resolved.conf ./tmp/root/etc/systemd/resolved.conf
fi

######################################################################
#/**
#  * Configuration customization.
#  * Making changes to the staged filesystem.
#  * non-master
#  *
#  */

else #this is not the master

  #nodes systemd network
  if [ ! -f ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network ]; then #not in a cloned/forked repo
  $_SUDO tee ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network > /dev/null <<EOF
[Match]
Name=lan0

[Network]
DHCP=ipv4
IPv6AcceptRouterAdvertisements=0
EOF
    $_SUDO cp ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network
  else
    $_SUDO cp ./application/physical/systemd/assets/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network ./tmp/root/etc/systemd/network/20_rpi-3-b_ethernetport.nonrouter.network
  fi

fi #end if else master=hostname

######################################################################
#/**
#  * This is a poor man's firstboot setup.
#  * 
#  * @ToDo: When it turns out stable, automate the process (there is no user input anyways) 
#  *
#  */

echo "shutdown -h 1" > ./tmp/root_root_.bash_history
if [ "$__HOSTNAME" = "$__MASTERHOSTNAME" ]; then
  echo "cat /var/lib/misc/dnsmasq.leases" >> ./tmp/root_root_.bash_history
  echo "salt '${__HOSTNAME}' test.ping" >> ./tmp/root_root_.bash_history
  echo "salt-key -L" >> ./tmp/root_root_.bash_history
  echo "salt-key -a ${__HOSTNAME} -y" >> ./tmp/root_root_.bash_history
  echo "salt '*' saltutil.refresh_pillar" >> ./tmp/root_root_.bash_history
  echo "salt-run jobs.active" >> ./tmp/root_root_.bash_history
  echo "salt 'axle'grains.append roles ntp-server" >> ./tmp/root_root_.bash_history
  echo "salt-run jobs.list_jobs" >> ./tmp/root_root_.bash_history
  echo "salt-run jobs.lookup_jid <job id number>" >> ./tmp/root_root_.bash_history
fi

tmp=''
if [ ! -z "$__MASTERHOSTNAME" ]; then tmp="-A ${__MASTERHOSTNAME} "; fi
if [ "$__HOSTNAME" = "$__MASTERHOSTNAME" ]; then tmp="${tmp} -M"; fi
_todolive="pacman -Syu --noconfirm";
if [ "$__HOSTNAME" = "$__MASTERHOSTNAME" ]; then _todolive=" ${_todolive}; pacman -S --noconfirm python2-pygit2 python2-yaml"; fi
_todolive=" ${_todolive}; curl -o bootstrap_salt.sh -L https://bootstrap.saltstack.com --silent -k; sleep 2; $_SUDO sh bootstrap_salt.sh -U -i ${__HOSTNAME} ${tmp} git v2016.11.2";
if [ "$__HOSTNAME" = "$__MASTERHOSTNAME" ]; then _todolive=" ${_todolive}; sleep 60; salt-key -A -y; echo 'Sleeping 60 seconds to settle down salt.'; sleep 60; salt '${__MASTERHOSTNAME}' state.apply dnsmasq; salt '${__MASTERHOSTNAME}' state.apply ntp-server; salt '${__MASTERHOSTNAME}' state.apply common; salt '${__MASTERHOSTNAME}' state.apply power-button"; fi
_todolive=" ${_todolive}; timedatectl set-ntp true;"

echo ${_todolive} >> ./tmp/root_root_.bash_history
$_SUDO mv ./tmp/root_root_.bash_history ./tmp/root/root/.bash_history

echo "su -" > ./tmp/root_home_alarm_.bash_history
$_SUDO mv ./tmp/root_home_alarm_.bash_history ./tmp/root/home/alarm/.bash_history

echo "Final step: Synchronizing data to SD card. May take a minute or so."
$_SUDO sync;

echo "To make changes to the SD card the partitions can be left mounted."
echo "In another shell one could make changes to the filesystem."
echo "The changes need to be made before the next SD card is written to, of course." #@TODO maybe "tainted" environment variable?
while true; do
  read -p "Unmount? [Yn] " yn
  [ -z "$yn" ] && yn="y"
  case $yn in
    [Yy]* ) $_SUDO umount ./tmp/boot ./tmp/root; break;;
    [Nn]* ) echo "Sure. Continuing..."; echo "Only allow the next card when editing is finished."; sleep 2; break;;
    * ) echo "Please answer yes or no";;
  esac
done

sleep 2; clear
echo -e "\nFinished!\n"
echo "As per https://archlinuxarm.org/platforms/armv8/broadcom/raspberry-pi-3 , do:"
echo "Insert the SD card into the Raspberry Pi, connect ethernet, and apply 5V power."
echo "Use the serial console or SSH to the IP address given to the board by your router."
echo " - Login as the default user alarm with the password alarm."
echo " - The default root password is root."
echo ""
echo "Login as root, followed by:"
echo ${_todolive}
echo ""
echo "This was written into the bash history of the root user. Login as root and press the arrow up key."
sleep 6
