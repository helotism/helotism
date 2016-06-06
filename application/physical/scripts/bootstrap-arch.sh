#!/usr/bin/env bash
#/** 
#  * This script writes Arch Linux ARM to SD cards which then cluster Rasperrry Pi 2 or 3.
#  * 
#  * Copyright (c) 2016 Christian Prior
#  * Licensed under the MIT License. See LICENSE file in the project root for full license information.
#  * 
#  * Usage: Call this script as root and it could own your system.
#  * @FIXME: sugarcoat this
#  * 
#  * @TODO: Nicer output
#  * 
#  */

set -o nounset #exit on undeclared variable
# bootstrap runtime
__BLOCKDEVICE='/dev/null'           #b
__BLOCKDEVICESIZE=0                 #if ~8GB and bigger, then only use ~5GB. The idea is to reserve space for a "data" partition.
__ROOTPARTITIONSIZE=''              #
_VERBOSE='false'                    #@TODO: Use it
# The remote repository
__GITREMOTEORIGINURL='https://github.com/helotism/helotism.git' #r
__GITREMOTEORIGINBRANCH='master'    #g
# About the cluster
__COUNT=2                           #c
__MASTERHOSTNAME='axle'             #m
__HOSTNAMEPREFIX='spoke0'           #n
__ADMINUSERNAME=''                  #u @TODO: not configurable yet
__ADMINUSERENCRYPTEDPASSWORD=''     #e @TODO: not configurable yet
# Network settings
__NETWORKSEGMENTCIDR='10.16.6.1/24' #s
__MASTERIP=''                       #
__NETWORKPREFIX='10.16.6.0'         #
__NETWORKSEGMENT='255.255.255.0'    #
__DHCPRANGESTARTIP=''               #a
__DHCPRANGEENDIP=''                 #o
__FQDNNAME='wheel.example.com'      #d

#http://stackoverflow.com/questions/18215973/how-to-check-if-running-as-root-in-a-bash-script
#The script needs root permissions to create the filesystem and manipulate the installation on the SD card
_SUDO=''
if (( $EUID != 0 )); then
  while true; do sudo ls; break; done
  _SUDO='sudo'
fi; #from now on this is possible: $SUDO some_command

#The workflow should be: https://github.com/helotism/helotism.git -> own fork -> local clone
#__GITREMOTEORIGINURL will then be the own fork
if [ -d '.git' ]; then
  __GITREMOTEORIGINURL=$(git remote get-url origin);
fi
#aggressively rewriting the URL because otherwise Saltstack needs SSH keys
if [ -d '.git' ];
then __GITREMOTEORIGINURL=$(git remote get-url origin);
  #long-winded but built-in
  __GITREMOTEORIGINURL=${__GITREMOTEORIGINURL/git@/}; #removes (if present)
  __GITREMOTEORIGINURL=${__GITREMOTEORIGINURL/https:\/\//}; #removes (if present)
  __GITREMOTEORIGINURL=${__GITREMOTEORIGINURL/://}; #should now have a root directory slash
  __GITREMOTEORIGINURL="https://${__GITREMOTEORIGINURL}"; #only https allowed in this script
fi ; 

#check if directories exist because the script should also run outside of a cloned repository context
#Creating a/p/s to prepare for a consitent location of curl'ed ./application/physical/scripts/sdcardsetup.sh
for d in 'data/incoming/archlinuxarm' 'tmp' 'application/physical/scripts'; do
  if [ ! -d $d ]; then mkdir -p ./$d; fi
done

#while getopts ":d:m:s:n:c:b:r:g:" opt; do
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
    g) __GITREMOTEORIGINBRANCH=$OPTARG
    ;;
    h) echo -e "Usage:\n sudo path/to/bootstrap-arch.sh"
    ;;
    i) __MASTERIP=$OPTARG
    ;;
    m) __MASTERHOSTNAME=$OPTARG
    ;;
    n) __HOSTNAMEPREFIX=$OPTARG
    ;;
    o) __DHCPRANGEENDIP=$OPTARG
    ;;
    p) echo "Only rpi-2 implemented yet. As of 2016-05 this is the official ArchLinuxARM way for rpi-3."; sleep 3; #_PLATFORM=$OPTARG
    ;;
    r) __GITREMOTEORIGINURL=$OPTARG
    ;;
    s) __NETWORKSEGMENTCIDR=$OPTARG
    ;;
    u) echo "The parameter -u for the __ADMINUSERNAME is not implemented yet;" #__ADMINUSERNAME=$OPTARG
    ;;
    v) _VERBOSE="true"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; echo -n "continuing "; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo ".";
    ;;
  esac;
done

#/**
#  * helper functions
#  *
#  */

#Trying to keep this to a minimum.
#Script tested and developed on Ubuntu 16.04
checkrequirements() {
  i=0;
  type wget >/dev/null 2>&1 || { echo >&2 "This script requires wget but it is not installed. ";  i=$((i + 1)); }
  type fdisk >/dev/null 2>&1 || { echo >&2 "This script requires fdisk but it is not installed. ";  i=$((i + 1)); }
  type curl >/dev/null 2>&1 || { echo >&2 "This script requires curl but it is not installed. ";  i=$((i + 1)); }
  type bsdtar >/dev/null 2>&1 || { echo >&2 "This script requires bsdtar but it is not installed. ";  i=$((i + 1)); }
  type dd >/dev/null 2>&1 || { echo >&2 "This script requires dd but it is not installed. ";  i=$((i + 1)); }
  type git >/dev/null 2>&1 || { echo >&2 "This script requires git but it is not installed. ";  i=$((i + 1)); }
  type lsblk >/dev/null 2>&1 || { echo >&2 "This script requires lsblk but it is not installed. ";  i=$((i + 1)); }

  if [[ $i > 0 ]]; then echo "Aborting."; echo "Please install the missing dependency."; exit 1; fi
} #end function checkrequirements

#/**
#  *
#  * As much configuration as necessary, as many conventions as sensible. Hopefully.
#  *
#  * The remote repository           :
#  * __GITREMOTEORIGINURL            : Saltstack contacts not just the local filesystem but remote Git repos
#  * __GITREMOTEORIGINBRANCH         : Will be used for the 'base' environment of Salststack
#  *
#  * About the cluster               :
#  * __COUNT                         : Up to 9; the number of RPi boards and SD cards
#  * __MASTERHOSTNAME                : Will get IP aaa.bbb.ccc.1 and set in all nodes' hosts file
#  * __HOSTNAMEPREFIX                : All nodes will be named alike
#  *
#  * Network settings                :
#  * __NETWORKSEGMENTCIDR            : Only /24 subnets allowed (arbitrary restriction to make the following computations easier)
#  * -> computes __MASTERIP          : aaa.bbb.ccc.1
#  * -> computes __NETWORKPREFIX     : aaa.bbb.ccc.0; used in ntp.conf
#  * -> computes __NETWORKSEGMENT    : 255.255.255.0; not computed but set explicitly
#  * __DHCPRANGESTARTIP              : aaa.bbb.ccc.100
#  * __DHCPRANGEENDIP                : aaa.bbb.ccc.200
#  * __FQDNNAME                      : The master runs an authoritative DHCP server for this subnet, so it should be unique for the cluster
#  *
#  */

#wrapped in function, called later
do_prompt_configuration() {
  
  while true; do
    echo "The config management pulls in defaults from a remote Git repo."
    echo "Only https:// links are allowed as otherwise SSH keys are involved."
    echo "This is technically possible but out of scope of this script."
    read -e -p "What Git repository do you want to reference? " -i "${__GITREMOTEORIGINURL}" __GITREMOTEORIGINURL
    if [[ "$__GITREMOTEORIGINURL" =~ ^https://([a-zA-Z]{1}([a-zA-Z\-]+))\.([a-zA-Z]{2,6})/([a-zA-Z/]*).git$ ]]; then
       break;
    else
      echo "${__GITREMOTEORIGINURL} is not valid, should be the https version and ending with .git"
    fi
  done
  
  while true; do
    read -e -p "Which branch: " -i "${__GITREMOTEORIGINBRANCH}" __GITREMOTEORIGINBRANCH
    if [ ! -z ${__GITREMOTEORIGINBRANCH} ]; then break; fi
  done

  while true; do
    read -e -p "How many cluster nodes in total shall be generated onto SD cards? [1-9] " -i "${__COUNT}" __COUNT
    if ! [ "$__COUNT" -eq "$__COUNT" ] 2> /dev/null ; then
      echo "Integer input values only."
    else
      if [ "$__COUNT" -le 9 -a "$__COUNT" -ge 1 ] ; then break; else echo "1-9 only"; fi
    fi
  done
  
  while true; do
    read -e -p "Enter hostname for a master server: " -i "${__MASTERHOSTNAME}" __MASTERHOSTNAME
    if [ ! -z ${__MASTERHOSTNAME} ]; then break; fi
  done

  while true; do
    echo "Enter the hostname prefix of the nodes."
    read -e -p "They will be appended with an integer, like '${__HOSTNAMEPREFIX}${__COUNT}': " -i "${__HOSTNAMEPREFIX}" __HOSTNAMEPREFIX
    if [ ! -z ${__HOSTNAMEPREFIX} ]; then break; fi
  done
  
  echo "Currently only /24 subnets are accepted."
  while true; do
    read -e -p "Enter a IPV4 address and prefix for this master: " -i "${__NETWORKSEGMENTCIDR}" __NETWORKSEGMENTCIDR
    if [[ "$__NETWORKSEGMENTCIDR" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])/24$ ]]; then #[0-9]{2}$ ]]; then
       __MASTERIP=${__NETWORKSEGMENTCIDR%.*}.1; #this overwrites any parameter supplied with -i
       __NETWORKPREFIX=${__NETWORKSEGMENTCIDR%.*}.0;
       __NETWORKSEGMENT='255.255.255.0'
       break;
    else
      echo "${__NETWORKSEGMENTCIDR} is not valid."
    fi
  done
  
  while true; do
    read -e -p "Start of a range for addresses handed out via DHCP : " -i "${__NETWORKSEGMENTCIDR%.*}.100" __DHCPRANGESTARTIP
    if [[ "$__DHCPRANGESTARTIP" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
      break;
    else
      echo "${__DHCPRANGESTARTIP} is not valid."
    fi
  done
  
  while true; do
    read -e -p "End of a range for addresses handed out via DHCP : " -i "${__NETWORKSEGMENTCIDR%.*}.200" __DHCPRANGEENDIP
    if [[ "$__DHCPRANGEENDIP" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
      break;
    else
      echo "${__DHCPRANGEENDIP} is not valid."
    fi
  done
  
  while true; do
    echo "Enter a dedicated fully qualified subdomain."
    read -e -p "The cluster nodes will be like '${__HOSTNAMEPREFIX}${__COUNT}.${__FQDNNAME}': " -i "${__FQDNNAME}" __FQDNNAME
    if [ ! -z ${__FQDNNAME} ]; then break; fi
  done

}

######################################################################
#/**
#  * Main part
#  *
#  */

clear

echo "Welcome to the bootstrap script for a Raspberry Pi cluster!"
echo "There will be additional prompts before anything gets overwritten."
while true; do
  read -p "Do you want to continue? [Yn] " yn
  [ -z "$yn" ] && yn="y"
  case $yn in
    [Yy]* ) break;;
    [Nn]* ) echo "Exiting."; exit;;
    * ) echo "Please answer yes or no.";;
  esac
done

checkrequirements
do_prompt_configuration

#/**
#  * Selecting the SD card that will be overwritten
#  *
#  * Asking the user to (re)insert the SD card that is being written to.
#  * Getting output from lsblk 2 times  in KEY="value" format and comparing before and after.
#  * This should be failsafe as a) an empty string b) two new blockdevices will both fail being written to
#  *
#  * @TODO: Wrap in function
#  *
#  */

__before=('init'); __after=('init'); __devices=(); i=0; __new='';

#fill the array __before with all block devices
while true; do
  read -p "Is the SD card removed from the reader? [yN] " yn
  [ -z "$yn" ] && yn="n"
  case $yn in
    [Yy]* ) while read device; do
              set -- $device;
              if [ ${1:0:4} = "NAME" ]; then
                eval "$1"; if [ ! -z $NAME ]; then __before+=($NAME); fi
              fi;
              done < <(lsblk -d -o "NAME,HOTPLUG,ROTA,TYPE" --paths --pairs --ascii | grep 'HOTPLUG="1"' | grep 'ROTA="0');
              break;;
    [Nn]* ) echo "Please remove the SD card.";;
    * ) echo "Please answer yes or no";;
  esac
done

echo "Please insert the SD card into the reader."
while true; do
  read -p "Is the SD card inserted into the reader? [yN] " yn
  [ -z "$yn" ] && yn="n"
  case $yn in
    [Yy]* ) while read device; do
              set -- $device;
              if [ ${1:0:4} = "NAME" ]; then
                eval "$1"; if [ ! -z $NAME ]; then __after+=($NAME); fi
              fi;
              done < <(lsblk -d -o "NAME,HOTPLUG,ROTA,TYPE" --paths --pairs --ascii | grep 'HOTPLUG="1"' | grep 'ROTA="0');
              break;;
    [Nn]* ) echo "Please remove the SD card.";;
    * ) echo "Please answer yes or no";;
  esac
done

#found this somewhere on stackexchange and I love it (mind the uniq -u):
#Throw away all elements that were present more than once
__new=$(echo ${__before[@]} ${__after[@]} | tr ' ' '\n' | sort | uniq -u);
if [ ! -z "$__new" ]; then
  __BLOCKDEVICE=${__new};
  #line=$(cat /proc/partitions | grep -E "${__BLOCKDEVICE}$");
  #set -- $line;
  #if [ "$3" -eq "$3" ]; then
  #  export __BLOCKDEVICESIZE=${3}; #should be integer
  #fi
else
  echo "Sorry, no newly inserted block device detected."
  echo "Aborting."
  echo "This script may be rerun with the preset variables:"
  echo "$0 -d ${__FQDNNAME} -m ${__MASTERHOSTNAME} -s ${__NETWORKSEGMENTCIDR} -c ${__COUNT} -n ${__HOSTNAMEPREFIX}";
  exit 1;
fi;


clear
echo -e -n "\nEnd of input phase"; sleep 1; echo -e ".\n\n"

#/**
#  * Writing a pillar file with the collected configuration items.
#  *
#  */

#See also: https://docs.saltstack.com/en/latest/topics/troubleshooting/yaml_idiosyncrasies.html#underscores-stripped-in-integer-definitions
#This is to trick out Jekyll
echo $'{\x25 load_yaml as vars \x25}' > ./tmp/srv_pillar_helotism.sls
echo "helotism:" >> ./tmp/srv_pillar_helotism.sls
dt=$(date --utc +%FT%TZ)
echo "  __datetimegenerated: \"${dt}\"" >> ./tmp/srv_pillar_helotism.sls;
for v in __GITREMOTEORIGINURL __GITREMOTEORIGINBRANCH __FQDNNAME __MASTERHOSTNAME  __MASTERIP __NETWORKSEGMENTCIDR __NETWORKPREFIX __NETWORKSEGMENT __DHCPRANGESTARTIP __DHCPRANGEENDIP __COUNT __HOSTNAMEPREFIX; do
  output="${v}: \"${!v}\""
  echo "  ${output}" >> ./tmp/srv_pillar_helotism.sls;
done
echo $'{\x25 endload \x25}' >> ./tmp/srv_pillar_helotism.sls
echo -e '\n{{ vars }}' >> ./tmp/srv_pillar_helotism.sls
#echo '{# https://github.com/saltstack/salt/issues/6955#issuecomment-110793057 #}' >> ./tmp/srv_pillar_helotism.sls

#/**
#  * Printing to the screen what will be done next.
#  *
#  */

#if [ ! -f "./application/physical/scripts/sdcardsetup.sh" ]; then
#  echo "./application/physical/scripts/sdcardsetup.sh not found. Downloading.";
#  #@TODO: Never forget to push to gh-pages.
#  #@TODO: Or rewrite everything to fully checkout the repo. Maybe a bit bloated.
#  if [ ! -d ./application/physical/scripts ]; then mkdir -p ./application/physical/scripts ; fi
#  curl -o ./application/physical/scripts/sdcardsetup.sh http://cprior.github.io/test/application/physical/scripts/sdcardsetup.sh
#  #exit;
#else
#  i=0; j=0;
#  while [ ${i} -lt ${__COUNT} ]; do
#    j=$(( $j + 1 ))
#    if [ $i -eq 0 ];then
#      echo "The master node will be on SD card no. ${j}: ${__MASTERHOSTNAME}"
#    else
#      echo "SD card no. ${j} will become: ${__HOSTNAMEPREFIX}${i}"
#    fi
#    i=$(( $i + 1 ))
#  done
#fi;
#echo -n "."; sleep 1; echo -n "."; sleep 1; echo -n ".";

#/**
#  * Now calling the setupscript for individual SD cards
#  *
#  */

i=0; j=0;
while [ ${i} -lt ${__COUNT} ]; do
  j=$(( $j + 1 )) #helper variable to count up the non-masterhost names
  if [ $i -eq 0 ];then

    clear
    #echo -e "\nThis is the master server."
    echo "Please insert the SD card no. ${j} into the reader for: ${__MASTERHOSTNAME}"
    echo "Press s to skip."
    while true; do
      read -p "Is the SD card inserted into the reader? [yNs] " yn
      [ -z "$yn" ] && yn="n"
      case $yn in
        [Yy]* ) sudo ./application/physical/scripts/sdcardsetup.sh -r ${__GITREMOTEORIGINURL} -g ${__GITREMOTEORIGINBRANCH} -n ${__MASTERHOSTNAME} -i ${__MASTERIP} -s ${__NETWORKSEGMENTCIDR} -m ${__MASTERHOSTNAME} -d ${__FQDNNAME} -a ${__DHCPRANGESTARTIP} -o ${__DHCPRANGEENDIP} -b ${__BLOCKDEVICE}; break;;
        [Nn]* ) echo "Please insert the SD card.";;
        [s]* ) break;;
        * ) echo "Please answer yes or no, or s to skip";;
      esac
    done

  else

    clear
    #echo -e "\nThis is a node."
    echo "Please insert the SD card no. ${j} into the reader for: ${__HOSTNAMEPREFIX}${i}"
    echo "Press s to skip."
    while true; do
      read -p "Is the SD card inserted into the reader? [yNs] " yn
      [ -z "$yn" ] && yn="n"
      case $yn in
        [Yy]* ) sudo ./application/physical/scripts/sdcardsetup.sh -r ${__GITREMOTEORIGINURL} -g ${__GITREMOTEORIGINBRANCH} -b ${__BLOCKDEVICE} -n ${__HOSTNAMEPREFIX}${i} -m ${__MASTERHOSTNAME} -i ${__MASTERIP} -s ${__NETWORKSEGMENTCIDR} -d ${__FQDNNAME}; break;;
        [Nn]* ) echo "Please insert the SD card.";;
        [s]* ) break;;
        * ) echo "Please answer yes or no, or s to skip";;
      esac
    done

  fi;
#end of while loop through $__COUNT
i=$(( $i + 1 ))
done
