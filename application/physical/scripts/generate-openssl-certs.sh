#!/usr/bin/env bash
#/**
#  * A bash script to generate with OpenSSL
#  * - a certificate authority,
#  * - intermediate and
#  * - server as well as
#  * - client certificates.
#  *
#  * Copyright (c) 2016-2018 Christian Prior
#  * Licensed under the MIT License. See LICENSE file in the project root for full license information.
#  *
#  * @SEE: https://jamielinux.com/docs/openssl-certificate-authority/index.html
#  * @SEE: https://www.phildev.net/ssl/creating_ca.html
#  * @SEE: https://stackoverflow.com/a/15061804 how to revoke without the certificate
#  *
#  *
#  */

set -o nounset #exit on undeclared variable

# bootstrap runtime
#__PREFIX='rack2.helotism.de' #p
if [[ -z "${HELOTISM_PKI_PREFIX_ENV}" ]]; then
  __PREFIX='rack2.helotism.de' #p
else
  __PREFIX="${HELOTISM_PKI_PREFIX_ENV}"
fi
__makerootca="False"         #r
__makeintermediateca="False" #i
__makediffiehellman="False"  #d
# declare -a does not pass set -o nounset
declare -a __CLIENTS         #c
declare -a __SERVERS         #s
declare -a __SERVERSANDCLIENTS
declare -a __SERVERSCLIENTSUNIQUE
#http://stackoverflow.com/q/59895
_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#_PATH=$(openssl version -d); if [ ! -d ${_PATH} ]; then echo "The path ${_PATH} does not exist! Exiting."; fi
#there is a mkdir $_PATH and ?????cd $_PATH later in the script
# set +o nounset
# if [[ ! -z "${HELOTISM_PKIDIR}" ]]; then
# echo ${HELOTISM_PKIDIR}
# fi
# set -o nounset
if [ -d "${_DIR}/../../../data" ];then 
_PATH="${_DIR}/../../../data/pki";
else
_PATH="./pki";
fi


usage () {
  echo "How to use:";
  echo "-p myPrefix:     create subdirectories for this prefix (alternatively set by HELOTISM_PKI_PREFIX_ENV).";
  echo "-r:              make a root certificate if not exists.";
  echo "-d:              make DiffieHellman 2048 parameter if not exists.";
  echo "-i:              make a intermediate certificate if not exists.";
  echo "-s srv1 -c srvN: make certs for these servers";
  echo "-c foo1 -c barN: make certs for these clients";
}

while getopts ":p:ridhc:s:" opt; do
  case $opt in
    p) __PREFIX=$OPTARG;;
    r) __makerootca="True";;
    i) __makeintermediateca="True";;
    d) __makediffiehellman="True";;
    c) __CLIENTS+=("$OPTARG");;
    s) __SERVERS+=("$OPTARG");;
    h  ) usage; exit;;
    \? ) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    :  ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
    *  ) echo "Unimplemented option: -$OPTARG" >&2; exit 1;;
  esac;
done
# https://stackoverflow.com/a/11279500
shift "$(($OPTIND - 1))" # (and more)

while true; do
  read -e -p "A prefix for a common naming convention : " -i "${__PREFIX}" __PREFIX
  if [ ! -z ${__PREFIX} ]; then break; fi
done

__rootCA="${__PREFIX}_root-ca"
__intermediateCA="${__PREFIX}_intermediate-ca"
__dh="${__PREFIX}_dh"
__publicChainCA="${__PREFIX}_ca-chained-public-crts"

if [ ! -d "$_PATH" ]; then
  mkdir -p "${_PATH}";
fi
##########################cd "${_PATH}"


######################################################################
#/**
#  * Main part
#  *
#  */


#/**
#  * Generate Diffie Hellman parameters / primes.
#  *
#  * @see `man dhparam`
#  *
#  */

if [ "$__makediffiehellman" = "True" ]; then

  #for illustrative purposes repeated twice
  for dir in "${__dh}" "${__dh}"; do
    if [ ! -d "${_PATH}/${dir}" ]; then mkdir -p "${_PATH}/${dir}"; fi
  done

  if [ ! -f "${_PATH}/${__dh}/dh2048.pem" ]; then
    echo "Create Diffie Hellman parameters."
    openssl dhparam -outform pem -out "${_PATH}/${__dh}/dh2048.pem" 2048
  fi

  #openssl dhparam -inform pem -in "${_PATH}/${__dh}/dh2048.pem" -text -noout
fi


#/**
#  * The root CA
#  *
#  */
if [ "$__makerootca" = "True" ]; then

  for dir in "${__rootCA}" "${__rootCA}/public-crts" "${__rootCA}/crl" "${__rootCA}/private-keys" "${__rootCA}/newcerts"; do
    if [ ! -d "${_PATH}/${dir}" ]; then mkdir -p "${_PATH}/${dir}"; fi
  done

  chmod 700 "${_PATH}/${__rootCA}/private-keys"

  if [ ! -f "${_PATH}/${__rootCA}/index" ]; then touch "${_PATH}/${__rootCA}/index"; fi
  if [ ! -f "${_PATH}/${__rootCA}/serial" ]; then openssl rand -hex 16 > "${_PATH}/${__rootCA}/serial"; fi

  if [ ! -f "${_PATH}/${__rootCA}/openssl.cnf" ];then
    if [ -f "${_DIR}/openssl-root.cnf" ]; then
      cp "${_DIR}/openssl-root.cnf" "${_PATH}/${__rootCA}/openssl.cnf";
      sed -i "s@^dir.*@dir = ${_PATH}/${__rootCA}@" "${_PATH}/${__rootCA}/openssl.cnf"
      sed -i "s@^private_key.*@private_key = \$dir/private-keys/${__rootCA}.pem.key@" "${_PATH}/${__rootCA}/openssl.cnf"
      sed -i "s@^certificate.*@certificate = \$dir/public-crts/${__rootCA}.pem.crt@" "${_PATH}/${__rootCA}/openssl.cnf"
    else
      echo "No config file template ${_DIR}/openssl-root.cnf"; exit;
    fi
  fi

  if [ ! -f "${_PATH}/${__rootCA}/private-keys/${__rootCA}.pem.key" ]; then
    echo "Create the root key (${__rootCA}.pem.key)"
    openssl genrsa -aes256 -out "${_PATH}/${__rootCA}/private-keys/${__rootCA}.pem.key" 4096
    chmod 400 "${_PATH}/${__rootCA}/private-keys/${__rootCA}.pem.key"
  else
    echo "The root CA key ./private-keys/${__rootCA}.pem.key already exists."
  fi

  if [ ! -f "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" ]; then
    echo "Use the root key (${__rootCA}.pem.key) to create a root certificate (${__rootCA}.pem.crt)"
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 20 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    openssl req -config "${_PATH}/${__rootCA}/openssl.cnf" -key "${_PATH}/${__rootCA}/private-keys/${__rootCA}.pem.key" -new -x509 -days ${days} \
    -sha256 -extensions v3_ca -out "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt"
    chmod 444 "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt"
    #openssl x509 -text -in "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" -noout | grep -A 1 X509v3
  else
    echo "The root certificate ./public-crts/${__rootCA}.pem.crt already exists."
    #openssl x509 -text -in "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" -noout | grep -A 1 X509v3
  fi
fi # end if __makerootca


#/**
#  * The intermediate CA ${__intermediateCA}
#  *
#  */
if [ "$__makeintermediateca" = "True" ]; then
  #clear

  if [ ! -f "${_PATH}/${__rootCA}/openssl.cnf" -o ! -f "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" ]; then
    echo "No Root CA configuration file or public certificate found to later sign an intermediate certificate. Exiting.";
    exit 1;
  fi

  for dir in  "${__intermediateCA}" "${__intermediateCA}/public-crts" "${__intermediateCA}/csr" "${__intermediateCA}/crl" "${__intermediateCA}/private-keys" "${__intermediateCA}/newcerts"; do
    if [ ! -d "${_PATH}/${dir}" ]; then mkdir -p "${_PATH}/${dir}"; fi
  done

  chmod 700 "${_PATH}/${__intermediateCA}/private-keys"

  if [ ! -f "${_PATH}/${__intermediateCA}/index" ]; then touch "${_PATH}/${__intermediateCA}/index"; fi
  if [ ! -f "${_PATH}/${__intermediateCA}/serial" ]; then openssl rand -hex 16 > "${_PATH}/${__intermediateCA}/serial"; fi
  if [ ! -f "${_PATH}/${__intermediateCA}/crlnumber" ]; then echo 1000 > "${_PATH}/${__intermediateCA}/crlnumber"; fi

  if [ ! -f "${_PATH}/${__intermediateCA}/openssl.cnf" ]; then
    if [ -f "${_DIR}/openssl-intermediate.cnf" ]; then
      cp "${_DIR}/openssl-intermediate.cnf" "${_PATH}/${__intermediateCA}/openssl.cnf";
      sed -i "s@^dir.*@dir = ${_PATH}/${__intermediateCA}@" "${_PATH}/${__intermediateCA}/openssl.cnf"
      sed -i "s@^private_key.*@private_key = \$dir/private-keys/${__intermediateCA}.pem.key@" "${_PATH}/${__intermediateCA}/openssl.cnf"
      sed -i "s@^certificate.*@certificate = \$dir/public-crts/${__intermediateCA}.pem.crt@" "${_PATH}/${__intermediateCA}/openssl.cnf"
    else
      echo "No config file template ${_DIR}/openssl-intermediate.cnf"; exit;
    fi
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.pem.key" ]; then
    echo "Create the intermediate key (${__intermediateCA}.pem.key)"
    openssl genrsa -aes256 -out "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.pem.key" 4096
    chmod 400 "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.pem.key"
  else
    echo "The intermediate key ./private-keys/${__intermediateCA}.pem.key already exists."
  fi


  if [ ! -f "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.pem.csr" ]; then
    echo "Use the intermediate key to create a certificate signing request (CSR)."
    openssl req -config "${_PATH}/${__intermediateCA}/openssl.cnf" -new -sha256 -key \
      "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.pem.key" \
      -out "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.pem.csr"
  else
    echo "The certificate signing request was already generated."
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.pem.crt" ]; then
    echo "To create an intermediate certificate, use the root CA with the v3_intermediate_ca extension to sign the intermediate CSR."
    #Signing as root
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 10 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    openssl ca -config "${_PATH}/${__rootCA}/openssl.cnf" \
      -create_serial -extensions v3_intermediate_ca \
      -startdate "${year}0101000000Z" -days ${days} -notext -md sha256 \
      -in "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.pem.csr" \
      -out "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.pem.crt"
    chmod 444 "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.pem.key"
    openssl x509 -text -in "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.pem.crt" -noout | grep -A 1 X509v3
  else
    echo "The intermediate certificate ${__intermediateCA}.pem.crt was already generated."
    #fixme: maybe validity check
  fi

  echo "Verify the intermediate certificate"
  openssl verify -CAfile "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.pem.crt"

  echo "Create the certificate chain file"
  cat "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.pem.crt" "${_PATH}/${__rootCA}/public-crts/${__rootCA}.pem.crt" > "${_PATH}/${__intermediateCA}/public-crts/${__publicChainCA}.pem.crt"
  chmod 444 "${_PATH}/${__intermediateCA}/public-crts/${__publicChainCA}.pem.crt"

  echo "Create an empty CRL file"
  openssl ca -config "${_PATH}/${__intermediateCA}/openssl.cnf" -gencrl -out "${_PATH}/${__intermediateCA}/public-crts/${__intermediateCA}.crl"

fi # end if __makeintermediateca


#/**
#  * messy bash arrays
#  *
#  */

set +o nounset

# which name is passed with both -c and -s ?
# https://stackoverflow.com/a/7877514
# This should not be done in bash, but whatever...

clients2=" ${__CLIENTS[*]} "              # add framing blanks
for item in ${__SERVERS[@]}; do
  if [[ $clients2 =~ " $item " ]] ; then  # use $item as regexp
    __SERVERSANDCLIENTS+=($item)
  fi
done
#echo "both: ${__SERVERSANDCLIENTS[@]}"

# arrats for internal use
clients_stringified=" ${__CLIENTS[*]} "
servers_stringified=" ${__SERVERS[*]} "
serversandclients_stringified=" ${__SERVERSANDCLIENTS[*]} "

# https://stackoverflow.com/a/13649357
serversclients=("${__CLIENTS[@]}" "${__SERVERS[@]}")
# Declare an associative array
declare -A tmparray
# Store the values of serversclients in arr4 as keys.
for k in "${serversclients[@]}"; do tmparray["$k"]=1; done
# Extract the keys.
__SERVERSCLIENTSUNIQUE=("${!tmparray[@]}")

# usage:
# for host in "${__SERVERSCLIENTSUNIQUE[@]}" ; do
#   if [[ $serversandclients_stringified =~ " $host " ]]; then
#     echo "$host is both";
#   elif [[ $clients_stringified =~ " $host " ]]; then
#     echo "$host is client";
#   elif [[ $servers_stringified =~ " $host " ]]; then
#     echo "$host is server"
#   fi
# done

set +o nounset
if [ ${#__SERVERSCLIENTSUNIQUE[@]} -eq 0 ]; then
  # nothing to do, reversing relaxing variable handling
  set -o nounset
else
# the array is filled, so -c and/or -s were passed in
  for host in "${__SERVERSCLIENTSUNIQUE[@]}" ; do
    if [[ $serversandclients_stringified =~ " $host " ]]; then
      extension="server_client_cert"
    elif [[ $clients_stringified =~ " $host " ]]; then
      extension="usr_cert"
    elif [[ $servers_stringified =~ " $host " ]]; then
      extension="server_cert"
    fi
  echo "$host $extension"
  done
fi


set -o nounset



#/**
#  * server and client certificates
#  *
#  */

set +o nounset
if [ ${#__SERVERSCLIENTSUNIQUE[@]} -eq 0 ]; then
  # nothing to do, reversing relaxing variable handling
  set -o nounset
else
# the array is filled, so -c and/or -s were passed in
  for host in "${__SERVERSCLIENTSUNIQUE[@]}" ; do
    extension="usr_cert"
    if [[ $serversandclients_stringified =~ " $host " ]]; then
      extension="server_client_cert"
    elif [[ $clients_stringified =~ " $host " ]]; then
      extension="usr_cert"
    elif [[ $servers_stringified =~ " $host " ]]; then
      extension="server_cert"
    fi
  #clear

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.key" ]; then
    echo "Create a key without passphrase for ${host}."
    openssl genrsa -out "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.key" 2048
    chmod 400 "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.key"
  fi

  #
  # Here the SubjectAlternativeNames (SAN)
  # https://security.stackexchange.com/questions/74345/

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.csr" ]; then
    echo "Use the private key to create a certificate signing request (CSR) for the subject /CN=${host}"
    openssl req -reqexts SAN -extensions SAN -config <(cat "${_PATH}/${__intermediateCA}/openssl.cnf" \
      <(printf "\n[SAN]\nsubjectAltName=DNS:example.com,DNS:www.example.com")) \
      -subj "/CN=${host}" \
      -key "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.key" \
      -new -sha256 -out "${_PATH}/${__intermediateCA}/csr/${host}.pem.csr"
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.pem.crt" ]; then
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 2 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    #Because of the missing RTC on some hardware there might be issues, or not
    #http://www.obj-sys.com/asn1tutorial/node15.html
    echo "Creating a certificate, signed by the intermediate CA, valid for ${days} days since the beginning of the year and with extension ${extension} "
    openssl ca -extensions ${extension} -config <(cat "${_PATH}/${__intermediateCA}/openssl.cnf" \
      <(printf "\n[alt_names]\nDNS.1 = localhost\nIP.1 = 127.0.0.1\nDNS.2 = ${host}\nDNS.3 = ${host}.${__PREFIX}")) \
      -create_serial  \
      -startdate "${year}0101000000Z" -days ${days} -notext -md sha256 \
      -in "${_PATH}/${__intermediateCA}/csr/${host}.pem.csr" \
      -out "${_PATH}/${__intermediateCA}/public-crts/${host}.pem.crt"
    chmod 444 "${_PATH}/${__intermediateCA}/public-crts/${host}.pem.crt"
  fi

  echo "Encoding the certificate for ${host} into DEM."
  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.dem.crt" ]; then
    openssl x509 -in "${_PATH}/${__intermediateCA}/public-crts/${host}.pem.crt" \
      -outform der -out "${_PATH}/${__intermediateCA}/public-crts/${host}.der.crt"
  fi

  echo "Verify the certificate for ${host}"
  openssl x509 -noout -text \
    -in "${_PATH}/${__intermediateCA}/public-crts/${host}.pem.crt"

  echo "Use the CA certificate chain file to verify that the new certificate has a valid chain of trust."
  openssl verify -CAfile "${_PATH}/${__intermediateCA}/public-crts/${__publicChainCA}.pem.crt" \
    "${_PATH}/${__intermediateCA}/public-crts/${host}.pem.crt"

done #for host
fi #if [ ${#__CLIENTS[@]} -eq 0 ]; then