---
layout: post
title:  "Asking for userinput with bash"
date:   2016-03-22 20:00:00 +0100
categories: [ application-physical_building-blocks ]
---

How to ask for input in a bash script.

This will continue as soon as the key is pressed:

```bash
asksure() {
  if [ -z "$1" ]
    then echo -n "Please select [Y]es or [N]o: (Y/N)? "
  else
    echo "${1} (Y/N)"
  fi

  while read -r -n 1 -s answer; do
    if [[ $answer = [YyNn] ]]; then
      [[ $answer = [Yy] ]] && retval=0
      [[ $answer = [Nn] ]] && retval=1
      break
    fi
  done
echo
return $retval 
}

if asksure "Continue?"; then
  echo "Continuing.";
else
  echo "Not continuing."
  exit
fi
```


This will continue only when enter is pressed:

```bash
  while true; do
      read -p "Do you wish to install this program? [yn] " yn
      case $yn in
          [Yy]* ) echo "yes entered"; break;;
          [Nn]* ) echo "exiting"; exit;;
          * ) echo "Please answer yes or no.";;
      esac
  done
```

This suggests an editable default:

```bash
VERSION=6
read -e -p "Enter/edit the subnet: " -i "10.16.${VERSION}.0" SUBNET

if [[ "$SUBNET" =~ ^((1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9]{1,2}|2[0-4][0-9]|25[0-5])$ ]]; then
  echo "${SUBNET} success"
else
  echo "${SUBNET} fail"
fi
```
