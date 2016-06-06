#!/usr/bin/env bash
#/** 
#  * Edit the helotism GitHub repository
#  * 
#  * Copyright (c) 2015 Christian Prior
#  * Licensed under the MIT License. See LICENSE file in the project root for full license information.
#  *
#  */

__USER='cprior'
__REPONAME='helotism'
__JSONSTRING='' #e.g. "has_wiki":"false" (with double quotes)
__VERBOSE='false'

while getopts ":hr:u:vj:" opt; do
  case $opt in
    h) echo "Usage: edit_github_repo.sh -j '\"foo\":\"bar\"'"; echo "See https://developer.github.com/v3/"; exit
    ;;
    r) __REPONAME=$OPTARG
    ;;
    u) __USER=$OPTARG
    ;;
    j) __JSONSTRING=$OPTARG
    ;;
    v) __VERBOSE="true"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; echo "Exiting. "; exit;
    ;;
  esac;
done

#Some poor man's error checking
e=0;
if [  "$__JSONSTRING" != "${__JSONSTRING/\"name\":/}" ]; then echo "-j cannot contain name. Exiting."; e=$((e + 1)); fi;
if [  "$__JSONSTRING" == "${__JSONSTRING/:/}" ]; then echo "-j did not contain a colon. Exiting."; e=$((e + 1)); fi;
if [  "$__JSONSTRING" == "${__JSONSTRING/\"/}" ]; then echo "-j did not contain double quotation markes. Exiting."; e=$((e + 1)); fi;
if [[ $e > 0 ]]; then exit; fi;

#safe_pattern=$(printf '%s\n' "$__JSONSTRING" | sed 's/\"/\\\"/g')
#echo $safe_pattern
#echo "$__JSONSTRING"
#exit

curl -u "${__USER}" -X PATCH https://api.github.com/repos/helotism/${__REPONAME} -d "{\"name\":\"${__REPONAME}\",${__JSONSTRING}}"
