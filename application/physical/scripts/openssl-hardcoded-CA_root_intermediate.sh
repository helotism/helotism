#!/usr/bin/env bash
#
# A script implementing (parts of) https://jamielinux.com/docs/openssl-certificate-authority/index.html
#

_PATH='/cygdrive/c/Users/christian.prior/Desktop/openssltests/script1'
#_PATH=$(openssl version -d); if [ ! -d ${_PATH} ]; then echo "The path ${_PATH} does not exist! Exiting."; fi
_PATH='/home/cpr/Desktop/openssltests'
_PATH='/home/cpr/helotism/helotism/data/pki'
__PREFIX='rack1.clt2017.helotism.de'      #p
__makerootca="False"         #r
__makeintermediateca="False" #i
#http://stackoverflow.com/q/59895
_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while getopts ":p:ri" opt; do
  case $opt in
    a) __PREFIX=$OPTARG
    ;;
    r) __makerootca="True"
    ;;
    i) __makeintermediateca="True"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2; echo -n "continuing "; sleep 1; echo -n "."; sleep 1; echo -n "."; sleep 1; echo ".";
    ;;
  esac;
done

while true; do
  read -e -p "A prefix for a common naming convention : " -i "${__PREFIX}" __PREFIX
  if [ ! -z ${__PREFIX} ]; then break; fi
done

__rootCA="${__PREFIX}-root-ca"
__intermediateCA="${__PREFIX}-intermediate-ca"
__publicChainCA="${__PREFIX}-ca-chained-public-certs"

if [ ! -d "$_PATH" ]; then
  mkdir -p "${_PATH}";
fi
cd $_PATH



### The root CA
if [ "$__makerootca" = "True" ]; then

  for dir in "${__rootCA}" "${__rootCA}/public-certs" "${__rootCA}/crl" "${__rootCA}/private-keys" "${__rootCA}/newcerts"; do
    if [ ! -d "${_PATH}/${dir}" ]; then mkdir -p "${_PATH}/${dir}"; fi
  done

  chmod 700 "${_PATH}/${__rootCA}/private-keys"

  if [ ! -f "${_PATH}/${__rootCA}/index" ]; then touch "${_PATH}/${__rootCA}/index"; fi
  if [ ! -f "${_PATH}/${__rootCA}/serial" ]; then echo 1000 > "${_PATH}/${__rootCA}/serial"; fi

  if [ ! -f "${_PATH}/${__rootCA}/openssl.cnf" ];then
    if [ -f "${_DIR}/openssl-root.cnf" ]; then
      cp "${_DIR}/openssl-root.cnf" "${_PATH}/${__rootCA}/openssl.cnf";
      sed -i "s@^dir.*@dir = ${_PATH}/${__rootCA}@" "${_PATH}/${__rootCA}/openssl.cnf"
      sed -i "s@^private_key.*@private_key = \$dir/private-keys/${__rootCA}.key.pem@" "${_PATH}/${__rootCA}/openssl.cnf"
      sed -i "s@^certificate.*@certificate = \$dir/public-certs/${__rootCA}.cert.pem@" "${_PATH}/${__rootCA}/openssl.cnf"
    else
      echo "No config file template ${_DIR}/openssl-root.cnf"; exit;
    fi
  fi

  if [ ! -f "${_PATH}/${__rootCA}/private-keys/${__rootCA}.key.pem" ]; then
    echo "Create the root key (${__rootCA}.key.pem)"
    openssl genrsa -aes256 -out "${_PATH}/${__rootCA}/private-keys/${__rootCA}.key.pem" 4096
    chmod 400 "${_PATH}/${__rootCA}/private-keys/${__rootCA}.key.pem"
  else
    echo "The root CA key ./private-keys/${__rootCA}.key.pem already exists."
  fi

  if [ ! -f "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" ]; then
    echo "Use the root key (${__rootCA}.key.pem) to create a root certificate (${__rootCA}.cert.pem)"
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 20 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    openssl req -config "${_PATH}/${__rootCA}/openssl.cnf" -key "${_PATH}/${__rootCA}/private-keys/${__rootCA}.key.pem" -new -x509 -days ${days} \
    -sha256 -extensions v3_ca -out "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem"
    chmod 444 "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem"
    #openssl x509 -text -in "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" -noout | grep -A 1 X509v3
  else
    echo "The root certificate ./public-certs/${__rootCA}.cert.pem already exists."
    #openssl x509 -text -in "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" -noout | grep -A 1 X509v3
  fi
fi # end if __makerootca



### The intermediate CA ${__intermediateCA}
if [ "$__makeintermediateca" = "True" ]; then
  clear

  if [ ! -f "${_PATH}/${__rootCA}/openssl.cnf" -o ! -f "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" ]; then
    echo "No Root CA configuration file or public certificate found to later sign an intermediate certificate. Exiting.";
    exit;
  fi

  for dir in  "${__intermediateCA}" "${__intermediateCA}/public-certs" "${__intermediateCA}/csr" "${__intermediateCA}/crl" "${__intermediateCA}/private-keys" "${__intermediateCA}/newcerts"; do
    if [ ! -d "${_PATH}/${dir}" ]; then mkdir -p "${_PATH}/${dir}"; fi
  done

  chmod 700 "${_PATH}/${__intermediateCA}/private-keys"

  if [ ! -f "${_PATH}/${__intermediateCA}/index" ]; then touch "${_PATH}/${__intermediateCA}/index"; fi
  if [ ! -f "${_PATH}/${__intermediateCA}/serial" ]; then echo 1000 > "${_PATH}/${__intermediateCA}/serial"; fi
  if [ ! -f "${_PATH}/${__intermediateCA}/crlnumber" ]; then echo 1000 > "${_PATH}/${__intermediateCA}/crlnumber"; fi

  if [ ! -f "${_PATH}/${__intermediateCA}/openssl.cnf" ]; then
    if [ -f "${_DIR}/openssl-intermediate.cnf" ]; then
      cp "${_DIR}/openssl-intermediate.cnf" "${_PATH}/${__intermediateCA}/openssl.cnf";
      sed -i "s@^dir.*@dir = ${_PATH}/${__intermediateCA}@" "${_PATH}/${__intermediateCA}/openssl.cnf"
      sed -i "s@^private_key.*@private_key = \$dir/private-keys/${__intermediateCA}.key.pem@" "${_PATH}/${__intermediateCA}/openssl.cnf"
      sed -i "s@^certificate.*@certificate = \$dir/public-certs/${__intermediateCA}.cert.pem@" "${_PATH}/${__intermediateCA}/openssl.cnf"
    else
      echo "No config file template ${_DIR}/openssl-intermediate.cnf"; exit;
    fi
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.key.pem" ]; then
    echo "Create the intermediate key (${__intermediateCA}.key.pem)"
    openssl genrsa -aes256 -out "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.key.pem" 4096
    chmod 400 "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.key.pem"
  else
    echo "The intermediate key ./private-keys/${__intermediateCA}.key.pem already exists."
  fi


  if [ ! -f "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.csr.pem" ]; then
    echo "Use the intermediate key to create a certificate signing request (CSR)."
    openssl req -config "${_PATH}/${__intermediateCA}/openssl.cnf" -new -sha256 -key \
      "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.key.pem" \
      -out "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.csr.pem"
  else
    echo "The certificate signing request was already generated."
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/public-certs/${__intermediateCA}.cert.pem" ]; then
    echo "To create an intermediate certificate, use the root CA with the v3_intermediate_ca extension to sign the intermediate CSR."
    #Signing as root
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 10 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    openssl ca -config "${_PATH}/${__rootCA}/openssl.cnf" -extensions v3_intermediate_ca \
      -startdate "${year}0101000000Z" -days ${days} -notext -md sha256 \
      -in "${_PATH}/${__intermediateCA}/csr/${__intermediateCA}.csr.pem" \
      -out "${_PATH}/${__intermediateCA}/public-certs/${__intermediateCA}.cert.pem"
    chmod 444 "${_PATH}/${__intermediateCA}/private-keys/${__intermediateCA}.key.pem"
    openssl x509 -text -in "${_PATH}/${__intermediateCA}/public-certs/${__intermediateCA}.cert.pem" -noout | grep -A 1 X509v3
  else
    echo "The intermediate certificate ${__intermediateCA}.cert.pem was already generated."
    #fixme: maybe validity check
  fi

  echo "Verify the intermediate certificate"
  openssl verify -CAfile "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" "${_PATH}/${__intermediateCA}/public-certs/${__intermediateCA}.cert.pem"

  echo "Create the certificate chain file"
  cat "${_PATH}/${__intermediateCA}/public-certs/${__intermediateCA}.cert.pem" "${_PATH}/${__rootCA}/public-certs/${__rootCA}.cert.pem" > "${_PATH}/${__intermediateCA}/public-certs/${__publicChainCA}.cert.pem"
  chmod 444 "${_PATH}/${__intermediateCA}/public-certs/${__publicChainCA}.cert.pem"

fi # end if __makeintermediateca



### Sign server and client certificates

#for host in axle.wheel.prdv.de spoke0{1,2,3,4}.wheel.prdv.de cog0{1,2,3,4}.wheel.prdv.de; do
for host in axle.rack1.clt2017.helotism.de spoke0{1,2,3,4}.rack1.clt2017.helotism.de cog0{1,2,3,4}.rack1.clt2017.helotism.de; do

  clear

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.key.pem" ]; then
    echo "Create a key without passphrase for ${host}."
    openssl genrsa -out "${_PATH}/${__intermediateCA}/private-keys/${host}.key.pem" 2048
    chmod 400 "${_PATH}/${__intermediateCA}/private-keys/${host}.key.pem"
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.csr.pem" ]; then
    echo "Use the private key to create a certificate signing request (CSR) for the subject /CN=${host}"
    openssl req -config "${_PATH}/${__intermediateCA}/openssl.cnf" \
      -subj "/CN=${host}" \
      -key "${_PATH}/${__intermediateCA}/private-keys/${host}.key.pem" \
      -new -sha256 -out "${_PATH}/${__intermediateCA}/csr/${host}.csr.pem"
  fi

  if [ ! -f "${_PATH}/${__intermediateCA}/private-keys/${host}.cert.pem" ]; then
    day=$(date +'%0d'); month=$(date +'%0m'); year=$(date +'%y'); futureyear=$(( $year + 2 ));
    days=$(( ($(date --date="${futureyear}${month}${day}" +%s) - $(date --date="${year}${month}${day}" +%s) )/(60*60*24) ))
    #Because of the missing RTC there might be issues, or not
    #http://www.obj-sys.com/asn1tutorial/node15.html
    openssl ca -config "${_PATH}/${__intermediateCA}/openssl.cnf" \
      -extensions server_cert -startdate "${year}0101000000Z" -days ${days} -notext -md sha256 \
      -in "${_PATH}/${__intermediateCA}/csr/${host}.csr.pem" \
      -out "${_PATH}/${__intermediateCA}/public-certs/${host}.cert.pem"
    chmod 444 "${_PATH}/${__intermediateCA}/public-certs/${host}.cert.pem"
  fi

  #echo "Verify the certificate for ${host}"
  #openssl x509 -noout -text \
  #      -in "${_PATH}/${__intermediateCA}/public-certs/${host}.cert.pem"

  echo "Use the CA certificate chain file to verify that the new certificate has a valid chain of trust."
  #openssl verify -CAfile "${_PATH}/${__intermediateCA}/public-certs/${__publicChainCA}.cert.pem" "${_PATH}/${__intermediateCA}/public-certs/${host}.cert.pem"

done #for host
